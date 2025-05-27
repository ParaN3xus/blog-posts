var magicNumbers141 = [
    // Mathematica 14.1+
    0xD1CF   // 14.1 - 14.1+
];

var magicNumbersMath130 = [
    // Mathematica 13.0+
    0x5417,  // 13.0 - 14.1+
    0xB013,  // 13.0 - 14.1+
    0xD54F,  // 13.0 - 14.1+
    0x66C0,  // 13.0 - 14.1+
    0x22DD,  // 13.0 - 14.1+
    0xCD2D,  // 13.0 - 14.1+
    0xB4D0   // 13.0 - 14.1+
];

var magicNumbersMath120 = [
    // Mathematica 12.0+
    0xE756,  // 12.0 - 14.1+
    0x8C68,  // 12.0 - 14.1+
    0x8250,  // 12.0 - 14.1+
    0xABEB,  // 12.0 - 14.1+
    0x60F0,  // 12.0 - 14.1
    0x8E3C   // 12.0 - 14.0
];

var magicNumbersMath102 = [
    // Mathematica 10.2+
    0x44F1,  // 10.2 - 13.3
    0x29C2,  // 10.2 - 13.2
    0xEE71,  // 10.2 - 13.1
    0xDB75,  // 10.2 - 13.0
    0xD227,  // 10.2 - 12.3
    0x2FDB   // 10.2 - 12.2
];

var magicNumbersMath100 = [
    // Mathematica 10.0+
    0xA439,  // 10.0 - 12.0
    0xE4A8,  // 10.0 - 12.1
    0xA68B,  // 10.0 - 12.0
    0x29F8,  // 10.0 - 11.3
    0x6A91,  // 10.0 - 11.2
    0x42DD,  // 10.0 - 11.1
    0x25DB   // 10.0 - 11.0
];

var magicNumbersSM130 = [
    // System Modeler 13.0+
    0x8C72,  // 13.0 - 14.1+
    0x4209,  // 13.0 - 14.1+
    0x73EE,  // 13.0 - 14.1+
    0x64EC,  // 13.0 - 14.1+
    0x7C53   // 13.0 - 14.1+
];

var magicNumbersSM050 = [
    // System Modeler  5.0+
    0x5770,  //  5.0 - 14.1+
    0x7C91,  //  5.0 - 14.1+
    0xEEFE,  //  5.0 - 14.1+
    0x1361,  //  5.0 - 14.1
    0x755E,  //  5.0 - 14.0
    0xA5CE,  //  5.0 - 13.3
    0xF536,  //  5.0 - 13.2
    0x1330,  //  5.0 - 13.1
    0xBF47   //  5.0 - 13.0
];

var magicNumbersSM040 = [
    // System Modeler  4.0+
    0x6188,  //  4.0 - 12.3
    0xAB0B,  //  4.0 - 12.2
    0xB4D3,  //  4.0 - 12.1
    0x47C5,  //  4.0 - 12.0
    0x81DD,  //  4.0 -  5.1?
    0x8330,  //  4.0 -  5.0
    0x72C4,  //  4.0 -  4.2
    0x2F33,  //  4.0 -  4.2
    0x6897,  //  4.0 -  4.1
    0x15BF   //  4.0
];
/*
var magicNumbersMathLM = [
    // MathLM
    0x72A4,
    0x29A5,
    0x140A,
    0x3FD1,
    0x452D,
    0x541A,
    0x3575,
    0x7F8C,
    0x6587,
    0x5B29
];
*/
var defaultActivationKey = '3893-9258-K6XJLE';

function genActivationKey() {
    s = "";
    for (let i = 0; i < 14; i++) {
        s += Math.floor(Math.random() * 10);
        if (i === 3 || i === 7)
            s += "-";
    }
    return s;
}

function genKeyValStr(mathID, activationKey = defaultActivationKey, maxLicenseProcessesSubprocesses = "", licenseType = "", licenseExpirationDate = "", licenseClass = "") {
    var keyValStr = "";
    if (typeof mathID !== "undefined" && mathID.length != 0) {
        keyValStr = mathID;
        if (typeof licenseExpirationDate !== "undefined" && licenseExpirationDate.length != 0) { keyValStr += "@" + licenseExpirationDate };
        if (typeof maxLicenseProcessesSubprocesses !== "undefined" && maxLicenseProcessesSubprocesses.length != 0) { keyValStr += ":" + maxLicenseProcessesSubprocesses };
        if (typeof licenseClass !== "undefined" && licenseClass.length != 0) { keyValStr += "*" + licenseClass };
        if (typeof licenseType !== "undefined" && licenseType.length != 0) { keyValStr += "$" + licenseType };
        if (typeof activationKey !== "undefined" && activationKey.length != 0) { keyValStr += "&" + activationKey }
        else { keyValStr += "&" + defaultActivationKey };

    };
    return keyValStr;
};

function keyValStr2licenseExpirationDate(keyValStr) {
    var licenseExpirationDate = "";
    var index1 = keyValStr.indexOf("@");
    var index2 = keyValStr.indexOf(":");
    var index3 = keyValStr.indexOf("*");
    var index4 = keyValStr.indexOf("$");
    var index5 = keyValStr.indexOf("&");
    if (index1 >= 0) {
        if (index2 >= 0) {
            licenseExpirationDate = keyValStr.substring(index1 + 1, index2);
        } else if (index3 >= 0) {
            licenseExpirationDate = keyValStr.substring(index1 + 1, index3);
        } else if (index4 >= 0) {
            licenseExpirationDate = keyValStr.substring(index1 + 1, index4);
        } else if (index5 >= 0) {
            licenseExpirationDate = keyValStr.substring(index1 + 1, index5);
        };
    };
    return licenseExpirationDate;
};

function keyValStr2maxLicenseProcessesSubprocesses(keyValStr) {
    var maxLicenseProcessesSubprocesses = "";
    var index2 = keyValStr.indexOf(":");
    var index3 = keyValStr.indexOf("*");
    var index4 = keyValStr.indexOf("$");
    var index5 = keyValStr.indexOf("&");
    if (index2 >= 0) {
        if (index3 >= 0) {
            maxLicenseProcessesSubprocesses = keyValStr.substring(index2 + 1, index3);
        } else if (index4 >= 0) {
            maxLicenseProcessesSubprocesses = keyValStr.substring(index2 + 1, index4);
        } else if (index5 >= 0) {
            maxLicenseProcessesSubprocesses = keyValStr.substring(index2 + 1, index5);
        };
    };
    return maxLicenseProcessesSubprocesses;
};

function keyValStr2licenseClass(keyValStr) {
    var licenseClass = "";
    var index3 = keyValStr.indexOf("*");
    var index4 = keyValStr.indexOf("$");
    var index5 = keyValStr.indexOf("&");
    if (index3 >= 0) {
        if (index4 >= 0) {
            licenseClass = keyValStr.substring(index3 + 1, index4);
        } else if (index5 >= 0) {
            licenseClass = keyValStr.substring(index3 + 1, index5);
        };
    };
    return licenseClass;
};

function keyValStr2licenseType(keyValStr) {
    var licenseType = "";
    var index4 = keyValStr.indexOf("$");
    var index5 = keyValStr.indexOf("&");
    if (index4 >= 0) {
        if (index5 >= 0) {
            licenseType = keyValStr.substring(index4 + 1, index5);
        };
    };
    return licenseType;
};

function testSalt(n, byte, c) {
    for (var bitIndex = 0; bitIndex <= 7; bitIndex += 1) {
        var bit = (byte >> bitIndex) & 1;
        if (bit + ((n - bit) & ~1) == n) {
            n = (n - bit) >> 1;
        } else {
            n = ((c - bit) ^ n) >> 1;
        };
    };

    return n;
};

function genPassword(keyValStr, salt) {
    var licenseExpirationDate = keyValStr2licenseExpirationDate(keyValStr);
    var maxLicenseProcessesSubprocesses = keyValStr2maxLicenseProcessesSubprocesses(keyValStr);
    var licenseClass = keyValStr2licenseClass(keyValStr);
    var licenseType = keyValStr2licenseType(keyValStr);

    salt = parseInt(salt);
    var uuid = keyValStr.split('').map(function (x) { return x.charCodeAt() });
    var salt1 = salt;
    for (var byteIndex = uuid.length - 1; byteIndex >= 0; byteIndex -= 1) {
        salt1 = testSalt(salt1, uuid[byteIndex], 0x105C3);
    };

    /*
        var offset1 = 0;
        while (testSalt(testSalt(salt1, offset1 & 0xFF, 0x105C3), offset1 >> 8, 0x105C3) !== 0xA5B6) {
            offset1 ++;
            if (offset1 >= 0xFFFF) {
                return '';
            }
        }
    */
    salt1 = salt1 ^ 0xCEDF;

    salt1 = Math.trunc(((salt1 + 0x72FA) & 0xFFFF) * 99999 / 0xFFFF);
    var offset1 = '0000' + salt1;
    offset1 = offset1.substring(offset1.length - 5);
    var salt2 = parseInt(offset1.substring(0, 2) + offset1.substring(3, 5) + offset1.substring(2, 3));
    salt2 = Math.trunc((salt2 / 99999.0) * 0xFFFF, 10) + 1;
    salt2 = testSalt(testSalt(0, salt2 & 0xFF, 0x1064B), salt2 >> 8, 0x1064B);
    for (var i = uuid.length - 1; i >= 0; i -= 1) {
        salt2 = testSalt(salt2, uuid[i], 0x1064B);
    };

    /*
        var offset2 = 0;
        while(testSalt(testSalt(salt2, offset2 & 0xFF, 0x1064B),
                        offset2 >> 8, 0x1064B) !== 0xA5B6) {
            offset2 += 1;
            if (offset2 >= 0xFFFF) { return ''; }
        }
    */
    salt2 = salt2 ^ 0xEF22;

    salt2 = Math.trunc((salt2 & 0xFFFF) * 99999 / 0xFFFF);
    var offset2 = '0000' + salt2;
    offset2 = offset2.substring(offset2.length - 5);
    var password = [
        offset2.charAt(3),
        offset1.charAt(3),
        offset1.charAt(1),
        offset1.charAt(0),
        '-',
        offset2.charAt(4),
        offset1.charAt(2),
        offset2.charAt(0),
        '-',
        offset2.charAt(2),
        offset1.charAt(4),
        offset2.charAt(1)
    ].join('');
    if ((maxLicenseProcessesSubprocesses.length > 0) || (licenseType.length > 0) || (licenseExpirationDate.length > 0) || (licenseClass.length > 0)) { password += ":" + maxLicenseProcessesSubprocesses };
    if ((licenseType.length > 0) || (licenseExpirationDate.length > 0) || (licenseClass.length > 0)) { password += ":" + licenseType };
    if ((licenseExpirationDate.length > 0) || (licenseClass.length > 0)) { password += ":" + licenseExpirationDate };
    if (licenseClass.length > 0) { password += ":" + licenseClass };
    return password;
};

function keygenMathematicaPlayerProSM(magicNumbers, mathID, activationKey = "", maxLicenseProcessesSubprocesses = "", licenseType = "", licenseExpirationDate = "", licenseClass = "") {
    var keyValStr = genKeyValStr(mathID, activationKey, maxLicenseProcessesSubprocesses, licenseType, licenseExpirationDate, licenseClass);
    return magicNumbers
        .map(function (magicNumber) { return genPassword(keyValStr, magicNumber) })
        .filter(function (password) { return password !== '' });
};

function printPass(documentTag, outputInnerHTML, passwordText) {
    var outputMathLMEl;
    var passwordMathLMEl;
    var passwordInnerCodeMathLMEl;

    outputMathLMEl = document.querySelector(documentTag);
    outputMathLMEl.innerHTML = outputInnerHTML;
    outputMathLMEl.append(document.createElement("br"));
    passwordMathLMEl = document.createElement("p");
    passwordInnerCodeMathLMEl = document.createElement("pre");
    passwordMathLMEl.append(passwordInnerCodeMathLMEl);
    passwordInnerCodeMathLMEl.innerText = passwordText;
    outputMathLMEl.append(passwordMathLMEl);
};

function genPass(event) {
    event.preventDefault();

    var formEl = document.querySelector('#form');
    if (formEl.reportValidity && !formEl.reportValidity()) { return; }
    var mathID = document.querySelector('#mathid').value;
    var activationKey = document.querySelector('#activation-key').value
    if (!activationKey) {
        activationKey = genActivationKey();
        document.querySelector('#activation-key').value = activationKey;
    }


    printPass(
        '#output141',
        'Password for Mathematica Enterprise 14.1+ or System Modeler 14.1+:',
        keygenMathematicaPlayerProSM(magicNumbers141, mathID, activationKey, "", "803000", "", "").join('\n')
    );

    printPass(
        '#outputMath130',
        'Password for Mathematica Enterprise 13.0+ (also work for System Modeler 14.1+):',
        keygenMathematicaPlayerProSM(magicNumbersMath130, mathID, activationKey, "", "803000", "", "").join('\n')
    );

    printPass(
        '#outputMath120',
        'Password for Mathematica Enterprise 12.0+ (the first 4 also work for System Modeler 14.1+):',
        keygenMathematicaPlayerProSM(magicNumbersMath120, mathID, activationKey, "", "803000", "", "").join('\n')
    );

    printPass(
        '#outputMath102',
        'Password for Mathematica Enterprise 10.2+:',
        keygenMathematicaPlayerProSM(magicNumbersMath102, mathID, activationKey, "", "3000", "", "").join('\n')
    );

    printPass(
        '#outputMath100',
        'Password for Mathematica Enterprise 10.0+:',
        keygenMathematicaPlayerProSM(magicNumbersMath100, mathID, activationKey, "", "3000", "", "").join('\n')
    );


    printPass(
        '#outputWPP130',
        'Password for Player Pro 13.0+:',
        keygenMathematicaPlayerProSM(magicNumbersMath130, mathID, activationKey, "", "40", "", "").join('\n')
    );

    printPass(
        '#outputWPP120',
        'Password for Player Pro 12.0+:',
        keygenMathematicaPlayerProSM(magicNumbersMath120, mathID, activationKey, "", "40", "", "").join('\n')
    );

    printPass(
        '#outputWPP102',
        'Password for Player Pro 10.2+:',
        keygenMathematicaPlayerProSM(magicNumbersMath102, mathID, activationKey, "", "40", "", "").join('\n')
    );

    printPass(
        '#outputWPP100',
        'Password for Player Pro 10.0+:',
        keygenMathematicaPlayerProSM(magicNumbersMath100, mathID, activationKey, "", "40", "", "").join('\n')
    );


    printPass(
        '#outputSM130',
        'Password for System Modeler 13.0+ (also work for Wolfram App 14.1+):',
        keygenMathematicaPlayerProSM(magicNumbersSM130, mathID, activationKey, "", "803000", "", "").join('\n')
    );

    printPass(
        '#outputSM050',
        'Password for System Modeler 5.0+ (the first 3 also work for Wolfram App 14.1+):',
        keygenMathematicaPlayerProSM(magicNumbersSM050, mathID, activationKey, "", "803000", "", "").join('\n')
    );

    printPass(
        '#outputSM040',
        'Password for System Modeler 4.0+:',
        keygenMathematicaPlayerProSM(magicNumbersSM040, mathID, activationKey, "", "", "", "").join('\n')
    );
};