#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "Unity AssetBundle CRC 算法逆向",
  desc: [
    记录了对 Unity 2022.3.62f3 版本的 AssetBundle CRC 算法的逆向过程, 并编写了一个等效实现, 以从任意 AssetBundle 文件计算 CRC 值.
  ],
  date: "2026-02-20",
  tags: (
    blog-tags.unity,
    blog-tags.reverse,
  ),
  license: licenses.cc-by-nc-sa,
)

= 背景

在 Unity 中, 各种加载 AssetBundle 的 API 如 `AssetBundle.LoadFromFile`, `AssetBundle.LoadFromMemory`, `UnityWebRequestAssetBundle.GetAssetBundle` 等都有含有 `uint crc` 参数的变体版本, 用于校验所要加载的 AssetBundle 是否正确.

有时, 我们修改了 AssetBundle 后需要让其它程序加载它. 这时若程序使用了 CRC 校验, 我们就需要计算出正确的 CRC 并将其替换. 虽说一种方法是直接使用 0, 这时上述 API 会跳过 CRC 检验, 但开发者可以轻易实现一个检查来避免这种 hack 成功.

== 问题

那么, 如何计算任意 AssetBundle 的 CRC 呢?

Unity 提供了 API `BuildPipeline.GetCRCForAssetBundle`, 但别被它的名字迷惑了. 实际上它只是读取穿入 AssetBundle 同目录下的 manifest 文件, 并从 manifest 文件中读取构建时预计算的 CRC 值. 如果不存在 manifest 文件, 这个函数什么都做不了.

事实是 Unity 官方并没有给出任何从 AssetBundle 文件计算 CRC 的公共 API (事实上, 经过反编译, 我其实发现私有 API 也没有). 而且这个 CRC 也并不是直接在 AssetBundle 文件上计算 CRC, 因为官方在 #link("https://docs.unity3d.com/6000.5/Documentation/Manual/AssetBundles-Integrity.html")[文档] 中声称
```
Unity calculates CRC values from the uncompressed content and the values remain consistent after compressing the content.
```
所以显然没那么简单.

一番搜索后, 非但没找到解决方案, 还在 Unity Discussions 上找到了若干个上古问题:
- https://discussions.unity.com/t/how-to-calculate-crc-from-a-bundle-file/194663
- https://discussions.unity.com/t/how-is-asset-bundle-crc-and-hash-created/596233
- https://discussions.unity.com/t/what-determine-the-crc-of-assetbundle/202751
- https://discussions.unity.com/t/way-to-check-asset-bundle-crc-before-attempting-to-load-it/876818
- https://discussions.unity.com/t/platform-asset-bundle-crc/164647


== 一种解决方案
不过一个#link("https://discussions.unity.com/t/instructions-on-how-to-generate-crc-checksums-to-use-with-loadfromcacheordownload/505022")[帖子]指出我们其实可以弯道超车: 在上述加载 AssetBundle 的 API 中提供错误的 CRC, 校验失败时 Unity 会给出如下 Log
```
CRC Mismatch. Provided [someRandomCRCForVerification], calculated [theRealCRC] from data. Will not load AssetBundle '[someRandom].assetbundle'
```
我们想要的 CRC 居然以这种方式得到了...

虽说目的达到了, 但是从错误日志中获取 CRC 实在太不优雅, 因此我还是决定看看 Unity 是如何计算 AssetBundle CRC 的.

= 逆向
我决定从 `AssetBundle.LoadFromFile` 开始追查.

在 #link("https://github.dev/duanjiahao/UnityDecompiled")[UnityDecompiled] 仓库中, 我找到了这个函数的声明:
```cs
[GeneratedByOldBindingsGenerator]
[MethodImpl(MethodImplOptions.InternalCall)]
public static extern AssetBundle LoadFromFile(string path, [UnityEngine.Internal.DefaultValue("0")] uint crc, [UnityEngine.Internal.DefaultValue("0")] ulong offset);

[ExcludeFromDocs]
public static AssetBundle LoadFromFile(string path, uint crc)
{
    ulong offset = 0uL;
    return AssetBundle.LoadFromFile(path, crc, offset);
}
```

`[MethodImpl(MethodImplOptions.InternalCall)]` 说明这是一个在 Unity 的 C++ 核心 UnityPlayer.dll 中实现的一个函数. IDA 启动.

在 IDA 中, 我搜索了上述日志中的关键常量 `CRC Mismatch`, 找到

```yasm
.rdata:00007FFD54B310D0 aCrcMismatchPro db 'CRC Mismatch. Provided %x, calculated %x from data. Will not load'
.rdata:00007FFD54B310D0                                         ; DATA XREF: AssetBundleLoadFromStreamAsyncOperation::FinalizeArchiveCreator(void):loc_7FFD537F38C5↑o
.rdata:00007FFD54B310D0                                         ; AssetBundleLoadFromAsyncOperation::InitializeAssetBundleStorage(FileSystemEntry &,VFS::FileSize,bool,unsigned __int64 *)+287↑o
```

第二个 XREF 看起来比较有希望, 该函数中的关键部分如下
```c
if ( v18 )
{
  while ( 1 )
  {
    v24 = *(_QWORD *)(a1 + 176);
    v49 = 0;
    v25 = v18 - v23;
    v60 = v23;
    v48 = &v68;
    if ( v22 < v18 - v23 )
      v25 = v22;
    if ( !(unsigned __int8)ArchiveStorageReader::Read(v24, &v60, v25, v56, v48, v49) )
      break;
    if ( !v68 )
      break;
    v26 = CRCFeed(v17, v56, v68);
    v23 += v68;
    v17 = v26;
    if ( v23 >= v18 )
      break;
    v22 = v58;
  }
}
v27 = CRCDone(v17);
v28 = *(_DWORD *)(a1 + 200);

// ...

v31 = Format(
        &v65,
        "CRC Mismatch. Provided %x, calculated %x from data. Will not load AssetBundle '%s'",
        v28,
        v27,
        v30);
```

此处, `ArchiveStorageReader::Read` 用于获取实际参与 CRC 计算的数据; `Graphine::Performance::IPerformanceManager::GetMissingStreamingTiles` 设置了 CRC 初始值; `CRCFeed` 和 `CRCDone` 是 CRC 的计算函数. 我们将一一深入

- `ArchiveStorageReader::Read`: 这个函数将 AssetBundle 中所有 block 的数据视作一个连续的虚拟字节流, 并且提供指定 `offset` 和 `size` 的读取. 关键部分如下
  ```c
  while ( 1 )
  {
  // virtual offset
  v22 = v50;

  // block index >= total_blocks
  if ( v21 >= v13 )
      goto LABEL_22;

  // starting offsets in the virtual byte stream of all blocks
  v23 = *(_QWORD *)(a1 + 280);

  // next block index = block_index + 1
  v24 = v21 + 1;

  // starting offset of current block in the virtual byte stream
  v25 = (_QWORD *)(v23 + 8LL * v21);
  // size of current block
  v26 = *(_QWORD *)(v23 + 8 * v24) - *v25;

  if ( *v25 > v18 + *v50 )
      goto LABEL_22;

  // remaining size = requested size - read
  v27 = a3 - v18;

  // if it's the first iter
  if ( v21 == v14 )
  {
      // offset in this block
      v28 = *(_DWORD *)v50 - *(_DWORD *)v25;
      // max size to read in this block
      v29 = v26 - v28;

      v49 = 0;

      // if this block if enough
      if ( v27 < (unsigned int)v26 - v28 )
      // read all remaining size
      v29 = a3 - v18;
      // else read full block. if so, v28 should be 0
      v30 = v29;
      if ( v28 )
      goto LABEL_18;
  }
  else // not the first iter
  {
      v28 = 0;
      // size of current block
      v30 = (unsigned int)v26;
      v49 = 0;
      // remaining size < block size
      if ( v27 < (unsigned int)v26 )
      // only read bytes of remaining size
      v30 = v27;
  }
  if ( v30 == v26 && (a6 & 1) == 0 )
  {
      // read complete block
      if ( !ArchiveStorageReader::ReadCompleteBlock(
              (ArchiveStorageReader *)a1,
              v21,
              (char *)v51 + v18, // buf
              &v49,
              (struct ArchiveStorageReader::BatchingFileReader *)&v37) )
      {
      core::vector<UnityEngine::Animation::GenericAnimationBindingCache::CustomBinding,0>::~vector<UnityEngine::Animation::GenericAnimationBindingCache::CustomBinding,0>(&v45);
      return 0;
      }
      goto LABEL_19;
  }
  LABEL_18:
  // read part of the block
  if ( !ArchiveStorageReader::ReadBlock(
          (ArchiveStorageReader *)a1,
          v21,
          v28,
          v30,
          (char *)v51 + v18, // buf
          &v49,
          (struct ArchiveStorageReader::BatchingFileReader *)&v37) )
  {
      v31 = v18;
      v32 = v18 != 0;
      goto LABEL_27;
  }
  LABEL_19:
  // read += iter_read
  v18 += v49;

  // read done
  if ( v49 >= v30 )
  {
      // move to the next block
      v21 = v24;

      // not enough
      if ( v18 < a3 )
      continue;
  }
  v22 = v50;
  LABEL_22:
  v6 = (char *)v51;

  // exit
  goto LABEL_23;
  }
  LABEL_23:
  ...
  ```
- `Graphine::Performance::IPerformanceManager::GetMissingStreamingTiles`: 初始值是 `0xFFFFFFFF`
  ```c
  __int64 __fastcall Graphine::Performance::IPerformanceManager::GetMissingStreamingTiles(
        Graphine::Performance::IPerformanceManager *this)
  {
    return 0xFFFFFFFFLL;
  }
  ```
- `CRCFeed`:
  ```c
  __int64 __fastcall CRCFeed(unsigned int a1, const unsigned __int8 *a2, __int64 a3)
  {
    __int64 v3; // rax

    for ( ; a3; --a3 )
    {
      v3 = *a2++;
      a1 = (a1 >> 8) ^ dword_7FFD54A4D5F0[v3 ^ (unsigned __int8)a1];
    }
    return a1;
  }
  ```
  其中 `dword_7FFD54A4D5F0` 是
  ```yasm
  .rdata:00007FFD54A4D5F0 dword_7FFD54A4D5F0 dd 0, 77073096h, 0EE0E612Ch, 990951BAh, 76DC419h, 706AF48Fh
  .rdata:00007FFD54A4D5F0                                         ; DATA XREF: CRCFeed(uint,uchar const *,unsigned __int64)+5↑o
  .rdata:00007FFD54A4D608                    dd 0E963A535h, 9E6495A3h, 0EDB8832h, 79DCB8A4h, 0E0D5E91Eh
  ...
  ```
  显然这是标准的 IEEE CRC32.
- `CRCDone`:
  ```c
  __int64 __fastcall CRCDone(int a1)
  {
    return (unsigned int)~a1;
  }
  ```

= 重新实现

基于上述信息, 为 #link("https://github.com/nesrak1/AssetsTools.NET")[AssetsTools.NET] 包实现了计算 AssetBundle CRC 的功能: https://github.com/nesrak1/AssetsTools.NET/pull/157

用法:
```cs
FileStream fs = File.OpenRead(bundlePath);
var reader = new AssetsFileReader(fs);
reader.BigEndian = true;

AssetBundleFile bundle = new AssetBundleFile();
bundle.Read(reader);

uint crc = BundleHelper.CalculateBundleCrc32(bundle);
```
