var file = "vestingData/holders.csv";
var data = require("fs").readFileSync(file, "utf8");
data = data.split("\r\n");

var _accounts = [];
var _fundsToVestArray = [];
var _vestingPeriods = [];
var _releaseDays = [];
var _roleOfAccounts = [];

data.forEach((row) => {
  var line = row.split(",");
  _accounts.push(line[0]);
  _fundsToVestArray.push(Number(line[1]));
  _vestingPeriods.push(Number(line[2]));
  _releaseDays.push(1657843200);
  _roleOfAccounts.push(line[3]);
});

console.log(_accounts.length);
console.log(_fundsToVestArray.length);
console.log(_vestingPeriods.length);
console.log(_releaseDays.length);
console.log(_roleOfAccounts.length);
console.log("_accounts", _accounts[0]);
console.log("_fundsToVestArray", _fundsToVestArray[0]);
console.log("_vestingPeriods", _vestingPeriods[0]);
console.log("_releaseDays", _releaseDays[0]);
console.log("_roleOfAccounts", _roleOfAccounts[0]);
