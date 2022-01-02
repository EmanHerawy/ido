function arrayToCSV(objArray) {
    const array = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray;
    let str = `${Object.keys(array[0]).map(value => `"${value}"`).join(",")}` + '\r\n';

    return array.reduce((str, next) => {
        str += `${Object.values(next).map(value => `"${value}"`).join(",")}` + '\r\n';
        return str;
    }, str);
}
// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require('fs');
const { format } = require('@fast-csv/format');
async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile 
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const accounts = await ethers.getSigners();


    /*******************************get Artifacts ******************************* */
    const ContractObj = await hre.ethers.getContractFactory("AnyERC20Launchpad");


    const _tokenContract = await ContractObj.attach("0x2E9d30761DB97706C536A112B9466433032b28e3");
   
    let streamOb = { dataStream:[]};
    // get all AirDropRequested log
    let eventFilter = _tokenContract.filters.AirDropRequested()
    let events = await (await _tokenContract.queryFilter(eventFilter, 15372801, 15372991)).map(async (data) => {
        const logs = await ContractObj.interface.
            decodeEventLog("AirDropRequested", data.data)
        streamOb.  dataStream.push({
            beneficiary: logs.beneficiary,
            amount: logs.amount.toNumber()
        });
        console.log(logs.beneficiary, 'test');
    }
    )
    // stringify JSON Object
    console.log(streamOb);
  const res= await fs.writeFileSync("output.json", JSON.stringify(streamOb, null))
 

 
 
    console.log({ res});
 

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
