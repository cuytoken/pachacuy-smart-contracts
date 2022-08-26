const { upgrades, ethers, hardhatArguments } = require("hardhat");
const hre = require("hardhat");

var { executeSet, callSequenceAgnostic } = require("../js-utils/helpers");
var pe = ethers.utils.parseEther;
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var bn = ethers.BigNumber.from;

// reading data from csv file
var file = "vestingData/airdrop1.csv";
var data = require("fs").readFileSync(file, "utf8");
data = data.split("\r\n");
var _accounts = [];
var _fundsToVestArray = [];
var _vestingPeriods = [];
var _releaseDays = [];
var _roleOfAccounts = [];
var date = "1658188800"; // Date and time (GMT): Tuesday, 19 July 2022 0:00:00
data.forEach((row) => {
  var line = row.split(",");
  _accounts.push(line[0]);
  _fundsToVestArray.push(pe(line[1]));
  _vestingPeriods.push(Number(line[2]));
  _releaseDays.push(date);
  _roleOfAccounts.push(line[3]);
});

async function main() {
  var [owner] = await ethers.getSigners();
  // var VestingAddress = "0x5E04a3e09DC8337eC480937620553624DaF6DB71"; // mumbai
  var VestingAddress = "0x39400fA10eAd44E551d3a76Fb1F1540618141730"; // mainnet
  var Vesting = await gcf("Vesting");
  var vesting = await Vesting.attach(VestingAddress);

  // executing
  var vt = vesting;
  var cm = "createVestingSchemaBatch";
  var inc = 40;
  var methods = [];

  for (var ix = 0; ix < Math.ceil(_accounts.length / inc); ix++) {
    function includePush(_ix) {
      if (_ix == 0) {
        methods.push(() => {
          var beg = _ix * inc;
          var end = Math.min((_ix + 1) * inc, _accounts.length);
          var _a = _accounts.slice(beg, end);
          var _f = _fundsToVestArray.slice(beg, end);
          var _v = _vestingPeriods.slice(beg, end);
          var _d = _releaseDays.slice(beg, end);
          var _r = _roleOfAccounts.slice(beg, end);
          return vt[cm](_a, _f, _v, _d, _r);
        });
      }
    }
    includePush(ix);
  }

  await callSequenceAgnostic(methods);
}

async function upgrade() {
  try {
    var VestingAddress = "0x39400fA10eAd44E551d3a76Fb1F1540618141730";
    const Vesting = await gcf("Vesting");
    await upgrades.upgradeProxy(VestingAddress, Vesting);
    console.log("Finish upgrade");
  } catch (error) {
    console.log("Error with Vesting", error);
  }
}

async function remove() {
  var accs = [
    "0xce4586eafe9566f7776ab8d284668fd17a5c0deb",
    "0xa7d52f6b2942d3238f3d0a1bc8feabf48bab4ed6",
    "0x56c246b01fbd17695a8579e8b3f0e4f7a1e9ccfc",
    "0xfc1fd9ecfbeaa38aa0ba51f630ba0b8656829afa",
    "0x45b81d8abc4488e73af27483e60369b2b4358194",
    "0xd61429462aa956f6e89f05629df448692149eaed",
    "0xe16f5ad57f9143c0c9bda9b9c79ea228b054add0",
    "0x1a48a2d012468815b8d9a65e8b560f492867ae51",
    "0xfa4d75ffda10023859391be7d671ad383e46457c",
    "0x19e24d91116491dfc151ac255a7a2a1756af52f8",
    "0xb43f41b70555add04fd1a341eccda84af60e81a3",
    "0x16989d9c96fe0170287c7e90cb94886bfa45854e",
    "0x6fdbc376bf2f19f2cf9a4628a2fc833deb41c8e6",
    "0xb14d7f26351198703d4b4501c38c1edd649326fc",
    "0x4020350bc7e17919dbf60096ff6c01a1e325225d",
    "0x8d63e248f54325494f3d3400a7bb81f767dc80b9",
    "0x7b7b9a51ef10fba216444e5913deec4b177b256f",
    "0xe12ef2d9724ab92362750331f791065f13ab3804",
    "0xdf4c0d0e4cb85cb31eba715ee67ca80ff015d152",
    "0x7f3e6101299b951fc122db7c834d659ded049263",
    "0x4deade9b828d240603488158a1b558b4c7ad9691",
    "0x8eef948275ebe94937111794793e3adf2a364085",
    "0x436a9808bdef2fe2dae9e1aeba8846ac76a5521a",
    "0x72c77230d2c6748f3e0a0479eb7aa33eb0687f61",
    "0xa91a307f4f32c221c32d6839e4b1b5473425bbd0",
    "0xdf52f4601e840752397e803c3093564b54853ff0",
    "0x89211f79116dad5b038be3dd4587dc6d47eb71b5",
    "0xf383203f2d96f033d163edd8dbc9a98ed2292a3a",
    "0x62f106f2d4eacbb254d973fd7013767b6a4d8e90",
    "0xbe03e0ada4a9c5e16ab2d881a2595225975e5d5f",
    "0x08b3e58d990faf976be18d1cbe2d96fbe934042a",
    "0xd30c9c7164530959ea7e9150445705d8c916a359",
    "0x1f2f8b73a0e6d6e3eebcbd462aece145a8622220",
    "0xcb3b0f409e2321c933170ee53460e64510e64dd8",
    "0x67409c7db424d3bfba13427a01682825cf06298e",
    "0xc345c8653cfc721bf832b8316565e2624a2565fc",
    "0x92c7ba98e8743339d95083205f89bbd96453c433",
    "0x80930f0b16ab9ce1cd803cc827b5b860f4c0c2e0",
    "0xa8ed41e846c0037dff19e937385c74f2c527edb3",
    "0xfbb8965bebcb62fdafa71f30b4efa6ee61423c6b",
  ];
  var uuids = Array(40)
    .fill(null)
    .map((_, ix) => 413 + ix);
  var VestingAddress = "0x39400fA10eAd44E551d3a76Fb1F1540618141730";
  var Vesting = await gcf("Vesting");
  var vesting = await Vesting.attach(VestingAddress);

  try {
    var tx = await vesting.removesVestingSchemaBatch(accs, uuids);
    var res = await tx.wait(1);
    console.log(res);
    console.log("Finish remove");
  } catch (error) {
    console.log("Error with Vesting", error);
  }
}

// main()
// upgrade()
remove()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
