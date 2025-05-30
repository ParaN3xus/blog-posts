#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "宝宝的强化学习",
  desc: [
    简单的强化学习入门, 包括马尔可夫决策过程, Q-Learning 和 DQN 算法的介绍和实现.
  ],
  date: "2025-02-28",
  tags: (
    blog-tags.ai,
    blog-tags.rl,
    blog-tags.math,
  ),
  license: licenses.cc-by-nc-sa,
)

#set math.equation(numbering: "(1)")


你可能或多或少听说过(或者十分了解)"监督学习", 也就是给出很多自变量-因变量对, 然后通过某种方式拟合那个函数.

但是监督学习并不能解决所有问题, 尤其是当我们没有那么多自变量-因变量对时候. 如果能把我们的问题转换成模型做出一些"动作", 从而和"环境"交互, 而且我们能较轻易地得知交互结果的好坏(无论是最终地还是暂时地), 我们能不能从这些结果的好坏中获得经验, 从而优化模型的行为呢?

= 环境? 动作? 结果?
我们暂时承认这个想法有可能是可行的, 但是为了搞清楚他是不是真的可行, 我们需要做一些严肃的推理和实验.

因此, 我们要先*形式化*这个问题.

我们用一个状态量 $s in S$ 来描述环境, 模型采取的行动 $a in A$ 会让 $s$ *改变*, 而且每次改变, 模型都会得到 $r(s,a)$ 的奖励(或者惩罚). 具体是怎么*改变*呢, 比较好(通用)的描述应该是产生一个下一状态的概率分布 $P(s' mid(|) s, a)$.

由于这显然是一个时序的过程, 所以我们定义时间步 $t < T$, 另外有在第 $t$ 步时的状态为 $S_t$, 模型行动为 $A_t$, 获得的奖励为 $R_t = r(S_t, A_t)$.

为了控制模型对近期和远期利益的倾向, 我们引入一个折扣因子 $gamma$, 并且定义从时刻 $t$ 开始直到结束, 模型获得的总回报为
$
  G_t = R_t + gamma R_(t + 1) + gamma^2 R_(t + 2) + ... = sum_(k = 0)^oo gamma^k R_(t + k)
$

还有最重要的, 我们的模型, 或者说"策略": $pi$. 我们将其定义为给定状态下采取各种行动的概率的分布, 也即 $pi(dot mid(|) s)$.

实际上, 我们定义的 $lr(angle.l S, A, P, r, gamma angle.r)$ 就是一个*马尔可夫决策过程*.


= 更多回报, 但是回报有多少?
我们希望得到更好的策略. 具体来说, 就是让该策略能够得到更大的总回报. 这种倾向反映在策略中, 也就是让一些能带来更大总回报的行动 $a$ 的概率更高.

而在状态 $s$ 上执行动作 $a$ 时, 遵循策略 $pi$ 的总回报期望(*动作价值函数*)是
$
  Q^pi (s, a) =& EE(G_t mid(|) s_t = s, a_t = a) \
  =& EE(sum_(k = 0)^oo gamma^k R_(t + k) mid(|) s_t = s, a_t = a) \
  =& EE(R_t + gamma sum_(k = 0)^oo gamma^k R_(t + k + 1) mid(|) s_t = s, a_t = a) \
  =& r(s,a) + gamma EE(sum_(k = 0)^oo gamma^k R_(t + k + 1) mid(|) s_t = s, a_t = a) \
$

这里 $s_(t + 1)$ 是一个分布, 如果能得知在某个状态上执行策略 $pi$ 的总回报期望(*状态价值函数*), 我们还能继续分解上式末尾的 $EE(dot)$, 于是我们定义这个值
$
  V^pi (s) = sum_(a in A) pi(a mid(|) s) Q^pi (s, a)
$
正如刚刚说的, 我们可以继续变形 $Q$:
$
  Q^pi (s, a) =& r(s,a) + gamma EE(sum_(k = 0)^oo gamma^k R_(t + k + 1) mid(|) s_t = s, a_t = a) \
  =& r(s,a) + gamma sum_(s' in S) P(s' mid(|) s, a) V^pi (s') \
$

现在看看我们得到了什么
$
  Q^pi (s, a) = r(s,a) + gamma sum_(s' in S) P(s' mid(|) s, a) V^pi (s')
$ <eq-q-raw>
$
  V^pi (s) = sum_(a in A) pi(a mid(|) s) Q^pi (s, a)
$ <eq-v-raw>

= 那么最优策略呢?
在我们推导了太多和一般策略有关的期望之后, 我们终于准备好研究一般策略的特例: *最优策略*.

事不宜迟, 我们定义一个策略 $pi^*$, 使得 $forall pi, forall s in S, V^pi^* (s) >= V^pi (s)$. 这是非常直观的最优策略, 因为无论在什么状态下, 其表现(回报期望)都比任意策略更好, 或至少一样.

根据该定义, 我们就有
$
  V^* (s) = max_pi V^pi (s)
$
和
$
  Q^* (s, a) = max_pi Q^pi (s, a)
$

一个好消息是, 既然最优策略是策略, 那他就符合我们上面推导出的一些结论, 比如 @eq-q-raw, 于是我们有
$
  Q^* (s, a) = r(s,a) + gamma sum_(s' in S) P(s' mid(|) s, a) V^* (s')
$ <eq-best-q-raw>

另一个好消息是, 既然最优策略是最优的, 他就会在每个状态上都采取 $Q$ 最大的 $a$. 那么除非若干个行动有相同的 $Q$, $pi^* (dot mid(|) s)$ 将会是 one-hot 的(只有一个行动的概率为 $1$, 其他都为 $0$), 否则其 $V$, 根据 @eq-v-raw, 将并非最大. 无论是多个相同 $Q$ 的行动分享 $1$ 还是 one-hot, 都有
$
  V^* (s) = max_(a in A) Q^* (s,a)
$ <eq-best-v-raw>
这其实是 @eq-v-raw 的简化版本.

@eq-best-q-raw 和 @eq-best-v-raw 看起来是两个互相耦合的函数, 不过既然如此, 我们也可以把它们互相代入, 得到递归的形式.

@eq-best-q-raw $->$ @eq-best-v-raw
$
  V^* (s) = max_(a in A) (r(s,a) + gamma sum_(s' in S) P(s' mid(|) s, a) V^* (s'))
$

@eq-best-v-raw $->$ @eq-best-q-raw
$
  Q^* (s, a) = r(s,a) + gamma sum_(s' in S) P(s' mid(|) s, a) max_(a' in A) Q^* (s',a')
$

这两个式子就是*贝尔曼最优方程*.

= 如何求出它?
策略是抽象的, 听上去似乎不像是什么可以求解的对象, 尤其是当我们并没有讨论具体问题的时候. 但是通过上面的这些推演, 我们已经把抽象的策略变成了具体的数学对象 $Q$ 和 $V$: 只要得到这两个函数中的一个(因为他们可以互相推导), 我们就事实上得到了最优策略, 因为我们可以选择 $arg max_a Q(s, a')$ 来让回报最大化.

下面我们不加#link("https://link.springer.com/content/pdf/10.1007/BF00992698.pdf", [证明])地给出 Q-Learning 的迭代公式.
$
  Q(s_t, a_t) <- Q(s_t, a_t) + alpha [R_t + gamma max_a Q(s_(t + 1), a) - Q(s_t, a_t)]
$ <eq-ql-iter>

当 Q-Learning 算法工作时, 我们先从一个随机初始化的 $Q$ 和状态 $s_t$ 开始, 将 $Q$ 当作 $Q^*$ 执行策略, 也即执行 $a_t = arg max_a Q(s_t, a_t)$. 每次得到环境的反馈 $R_t, s_(t+1)$ 后, 就进行一次迭代, 然后重复这个过程.

虽然我并不打算细讲这个迭代公式的收敛性的具体证明过程, 但是我们还是有必要从直观上理解这个公式. 我们主要关注增量部分, 它包含
- $alpha$: 这是一个可调参数, 用于控制学习率, 这很好理解
- $R_t + gamma max_a Q(S_(t+1), a)$: 利用环境给出的信息 $R_t$ 展开 $Q$ 的一项, 这是我们给出的新的 $Q$ 的估计. 由于它正确地利用了环境给出的信息, 所以直觉上应该比原始的 $Q$ 更接近最优
- $-Q(s_t, a_t)$: 减去原本的 $Q$ 的估计, 得到增量部分, 这很好理解

但是这还不够, 事实上 Q-Learning 在选择动作时并没有完全按照估计的 $Q$ 执行------算法执行初期我们希望得到更多环境的信息, 所以我们需要一些随机探索.

所以实际上 Q-Learning 采用的是 $epsilon$-贪心算法, 也就是有 $epsilon$ 的概率随机选择 $a in A$ 执行, 剩余的 $1-epsilon$ 则贪心地选择 $arg max_a Q(s_t, a_t)$, 然后我们可以令 $epsilon$ 随时间衰减, 就能达到我们"在算法运行初期增加随机探索"的目的了.

然而, Q-Learning 有个巨大的缺点: 他只能处理 $S$ 和 $A$ 都是有限集合的情形, 因为迭代公式只是在更新单个自变量的值. 这真是太坏了, 因为现实中的很多问题都是连续的, $S$ 和 $A$ 都是巨大的实向量空间, 这种情况下我们显然不能更新单个自变量对应的函数值来得到 $Q$, 我们要怎么办?

= 函数拟合? 有了
据我们所知, 神经网络很擅长这种拟合函数的工作. 但是要在这种问题上采用神经网络, 我们还需要得知网络的更新方式: 我们需要损失值.

损失值基本上就是模型输出和正确结果(至少是"更正确")之间的差异, 带着这种观点重新审视 @eq-ql-iter, 我们会发现答案就在其增量部分. 只要简单地套上一个 $"MSE"$, 我们就找到了损失值
$
  L = op("MSE")(R_t + gamma max_a Q(s_(t + 1), a) , Q(s_t, a_t))
$ <eq-dqn-loss>

我们已经很接近 *DQN*(Deep Q Network) 算法了, 还剩下一点实践中的考量

== 不要浪费样本
神经网络当然不能像 Q-Learning 那样采样一次就利用这次采样的数据迭代一次: 这样得到的数据并不"同分布", 于是神经网络只能学习到最近的数据; 每个样本只使用了一次, 效率太低.

所以, 我们会先连续地在环境中采样, 并把采样得到的 $(s_t, a_t, R_t, s_(t + 1))$ 保存到一个*缓冲区*中, 等到缓冲区中有一定数量的样本后, 再进行训练.

== "参考答案"也有网络的输出
我们这个神经网络的训练和监督学习的训练略有不同: $"MSE"$ 的两项都包含神经网络本身的输出, 更新网络的时候目标也在改变, 这会导致训练不稳定.

所以我们干脆使用两套网络, 一套*目标网络*暂不更新, 用于计算 $max_a Q(s_(t + 1), a)$, 另一套正常更新, 用于计算 $Q(s_t, a_t)$. 只有每隔 $C$ 步, 才把目标网络和正常更新的网络进行同步, 从而保证训练的稳定性.

= 我想试试看
我已经跃跃欲试了, 有没有什么问题简单又适合 DQN 的让我做一做?

有的兄弟, 有的. 下面我们来看一个经典问题: 车杆问题(Cart-Pole Problem).

车杆问题(如 @fig-cart-pole)是一个经典控制问题, 其基本环境由一个可在水平轨道上左右移动的小车和一根铰接在小车上的直杆组成. 杆的初始状态略有倾斜, 因此会因重力而自然倾倒. 我们的目标是通过控制小车的左右移动, 使杆保持竖直平衡状态尽可能长的时间, 要求杆与竖直方向的夹角不超过特定阈值, 同时小车不能超出轨道边界.

#figure(
  auto-div-frame(theme => cetz.canvas(
    length: 2em,
    {
      import cetz.draw: *

      set-style(stroke: theme.main-color)

      line((-2, 0.25), (2, 0.25))
      circle((-0, 0.5), radius: 0.1)

      rect((-0.5, 0), (0.5, 0.5))

      line((0, 0.5), (0, 2))

      content((0, -0.4), "Cart")
      content((0.7, 1.2), "Pole")
    },
  )),
  caption: [车杆问题示意图],
) <fig-cart-pole>

== 定义环境
好消息是 Python 包 `gymnasium` 已经为我们实现了这个环境的代码, 我们可以直接调用.

```python
from gymnasium.envs.classic_control import CartPoleEnv
from gymnasium.wrappers.common import TimeLimit

def get_env(render: False, max_step=-1):
    raw_env = CartPoleEnv(render_mode="human" if render else None)
    if max_step > 0:
        return TimeLimit(raw_env, max_episode_steps=max_step)
    return raw_env
```

这里不使用 `gym.make("CartPole-v1")` 的原因是其限制了最长步数为 500, 这样的步数仍然过短, 模型可能陷入局部最优解, 比如任小车以较慢的速度滑出有效区域.

这个环境的 $S$ 和 $A$ 如下表所示.

#figure(
  table(
    columns: 2,
    [状态], [取值区间],
    [车的位置], [$[-4.8, 4.8]$],
    [车的速度], [$RR$],
    [杆的角度], [$[-0.418, 0.418]$],
    [杆末端的角速度], [$RR$],
  ),
  caption: [车杆问题状态空间],
) <tbl-cartpole-s>

#figure(
  table(
    columns: 2,
    [动作], [值],
    [向左推车], [$0$],
    [向右推车], [$1$],
  ),
  caption: [车杆问题动作空间],
) <tbl-cartpole-a>

只要坚持一帧, 就能获得分数为 $1$ 的奖励.

== 设计 Q 网络
根据环境的 $S$ 和 $A$, 我们需要设计一个接收一个四维向量, 并输出一个二维向量的网络. 我这里给出一个例子.
```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class QNet(nn.Module):
    def __init__(self, state_size=4, action_size=2):
        super(QNet, self).__init__()

        self.fc1 = nn.Linear(state_size, 64)
        self.fc2 = nn.Linear(64, 64)
        self.fc3 = nn.Linear(64, action_size)

        self._initialize_weights()

    def _initialize_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.kaiming_normal_(m.weight, mode='fan_in', nonlinearity='relu')
                nn.init.constant_(m.bias, 0)

    def forward(self, state):
        if state.dim() == 1:
            state = state.unsqueeze(0)

        x = F.relu(self.fc1(state))
        x = F.relu(self.fc2(x))
        q_values = self.fc3(x)

        return q_values
```
这是一个具有两个隐藏层的网络, 并使用 ReLU 作为激活函数, 还使用了 He 初始化, 优化了初期的训练.

== 样本缓冲区
我们用 `collections.deque` 做一个简单的样本缓冲区, 可以向里面存入样本, 然后随机地取出.

```python
import collections
import random
import numpy as np

class SampleBuffer:
    def __init__(self, max_size):
        self.buffer = collections.deque(maxlen=max_size)

    def add(self, state, action, reward, next_state, done):
        self.buffer.append((state, action, reward, next_state, done))

    def sample(self, batch_size):
        samples = random.sample(self.buffer, batch_size)
        state, action, reward, next_state, done = zip(*samples)
        return np.array(state), action, reward, np.array(next_state), done

    def size(self):
        return len(self.buffer)
```

== DQN 算法
正如我们前面所说的, 我们实现 DQN 算法的更新算法和$epsilon$-贪心策略. 有一点不同的是, 我们的环境会因为某些原因终止, 比如杆的角度或者小车位置超出范围, 到达最大时间等. 当环境终止时, 要把 @eq-dqn-loss $"MSE"$ 中第一项(也即下面代码的 `q_targets`) 中对未来的估计部分变为 $0$, 因为环境已经终止, 未来不会有任何回报了.

```python
class DQN:
    def __init__(self, state_dim, action_dim, learning_rate, gamma, epsilon, target_update_freq, device):
        self.action_dim = action_dim

        self.q_net = QNet(state_dim, action_dim).to(device)
        self.target_q_net = QNet(state_dim, action_dim).to(device)

        self.optimizer = torch.optim.Adam(
            self.q_net.parameters(), lr=learning_rate)
        self.gamma = gamma
        self.epsilon = epsilon
        self.target_update = target_update_freq
        self.update_count = 0
        self.device = device

    def take_action(self, state):
        # epsilon-greedy
        if np.random.random() < self.epsilon:
            action = np.random.randint(self.action_dim)
        else:
            state = torch.tensor([state]).to(self.device)
            action = self.q_net(state).argmax().item()
        return action

    def update(self, transition_dict):
        states = torch.tensor(transition_dict['states']).to(self.device)
        actions = torch.tensor(
            transition_dict['actions']).view(-1, 1).to(self.device)
        rewards = torch.tensor(
            transition_dict['rewards']).view(-1, 1).to(self.device)
        next_states = torch.tensor(
            transition_dict['next_states']).to(self.device)
        dones = torch.tensor(
            transition_dict['dones']).view(-1, 1).to(self.device)

        # Q(s_t, a_t)
        q_values = self.q_net(states).gather(1, actions)

        # max_a Q(s_(t + 1), a)
        max_next_q_values = self.target_q_net(
            next_states).max(1)[0].view(-1, 1)

        # r(s, t) + gamma max_a Q(s_(t + 1), a), mul (1-done) for obvious reason
        q_targets = rewards + self.gamma * max_next_q_values * (1 - dones)

        loss = F.mse_loss(q_targets, q_values)

        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        # update target network
        if self.update_count % self.target_update == 0:
            self.target_q_net.load_state_dict(self.q_net.state_dict())
        self.update_count += 1
```

== 开始训练
设置参数, 初始化模型, 然后根据我们前面所述的策略启动训练.

```python
import tqdm.notebook as tqdm

device = torch.device(
    "cuda") if torch.cuda.is_available() else torch.device("cpu")

lr = 2e-3
num_episodes = 500
gamma = 0.98
epsilon = 0.01
target_update = 10
buffer_size = 10000
min_buffer_size = 500
batch_size = 64

env = get_env(render=False, max_step=2000)
replay_buffer = SampleBuffer(buffer_size)
state_dim = env.observation_space.shape[0]
action_dim = env.action_space.n
agent = DQN(state_dim, action_dim, lr, gamma, epsilon,
            target_update, device)

return_list = []
for i in range(10):
    with tqdm.tqdm(range(int(num_episodes / 10)), desc='Iteration %d' % i) as pbar:
        for i_episode in pbar:
            episode_return = 0
            state, _ = env.reset()
            done = False
            while not done:
                action = agent.take_action(state)
                next_state, reward, terminated, truncated, _ = env.step(action)
                done = terminated or truncated
                replay_buffer.add(state, action, reward, next_state, 1 if done else 0)
                state = next_state
                episode_return += reward

                # train after there are enough samples
                if replay_buffer.size() > min_buffer_size:
                    b_s, b_a, b_r, b_ns, b_d = replay_buffer.sample(batch_size)
                    transition_dict = {
                        'states': b_s,
                        'actions': b_a,
                        'next_states': b_ns,
                        'rewards': b_r,
                        'dones': b_d
                    }
                    agent.update(transition_dict)
            return_list.append(episode_return)
            if (i_episode + 1) % 10 == 0:
                pbar.set_postfix({
                    'episode':
                    '%d' % (num_episodes / 10 * i + i_episode + 1),
                    'return':
                    '%.3f' % np.mean(return_list[-10:])
                })
```

== 观察结果
新建一个有可视化界面的环境, 然后看看模型的表现吧!

```python
env = get_env(render=True)

state, _ = env.reset()
done = False
while not done:
    action = agent.take_action(state)
    env.render()
    next_state, reward, terminated, truncated, _ = env.step(action)
    done = terminated or truncated
    state = next_state
```

不出意外的话, 你的模型应该能很好地控制住杆, 直到永远.

如果不幸没有, 请再仔细检查代码有没有错误. 此外由于我并没有设置任何 `seed`, 所以这种情况也是完全有可能发生的, 可以再尝试几次, 或者尝试修改超参数.

无论如何, it works on my machine.

= 好像还缺点什么
我们批评过 Q-Learning 只能学习离散状态空间中的 $Q$ 函数, 但现在我们的 DQN 也不能给出连续的动作.

是的, 所以研究者们还提出了基于"策略梯度"的算法(DQN是基于值函数的), 比如 REINFORCE, 这种算法可以预测连续的动作. 除此之外, 还有混合两种思想的算法, 比如 Actor-Critic, PPO, DDPG 等. 但是这些算法都不在本文的计划范围之内了.

至此, 我们已经完成了对强化学习基础概念和两种入门算法的介绍. 从最初的马尔可夫决策过程, 到价值函数, 策略函数的概念, 再到 Q-Learning 和 DQN 算法的实现, 我们循序渐进地窥见了强化学习的一点思想.

不管怎样, 强化学习是一个广阔而深刻的领域, 本文也将仅仅止步与其思想和入门算法的介绍. 上面提到的其他算法并不在本文的计划内容范围内. 若有兴趣, 可以自行了解.

希望你有所收获.

