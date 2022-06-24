import Web3 from "web3";
import { newKitFromWeb3 } from "@celo/contractkit";
import BigNumber from "bignumber.js";
import erc20Abi from "../contract/erc20.abi.json";
import seloWorldAbi from "../contract/SeloWorld.abi.json";

const ERC20_DECIMALS = 18;
const MPContractAddress = "0xfa2B0f065A83d01568bFcd32C97BaDfF345F624a";
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

let kit;
let contract;
let lands = [];

const connectCeloWallet = async function () {
  if (window.celo) {
    try {
      notification("⚠️ Please approve this DApp to use it.");
      await window.celo.enable();
      notificationOff();

      const web3 = new Web3(window.celo);
      kit = newKitFromWeb3(web3);

      const accounts = await kit.web3.eth.getAccounts();
      kit.defaultAccount = accounts[0];

      contract = new kit.web3.eth.Contract(seloWorldAbi, MPContractAddress);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.");
  }
};

const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount);
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2);
  document.querySelector("#balance").textContent = cUSDBalance;
};

async function approve(_bid) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress);
  const result = await cUSDContract.methods
    .approve(MPContractAddress, _bid)
    .send({ from: kit.defaultAccount });
  return result;
}

const getLands = async function () {
  const _landsLength = await contract.methods.GetLandsLength().call();
  const _lands = [];

  for (let i = 0; i < _landsLength; i++) {
    let _land = new Promise(async (resolve, reject) => {
      let p = await contract.methods.ReadAuction(i).call();
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        minPrice: new BigNumber(p[3]),
        highestBid: new BigNumber(p[4]),
        highestBidder: p[5],
      });
    });
    _lands.push(_land);
  }
  lands = await Promise.all(_lands);
  renderLands();
};

function renderLands() {
  document.getElementById("marketplace").innerHTML = "";
  lands.forEach((_land) => {
    const newDiv = document.createElement("div");
    newDiv.className = "col-md-4";
    newDiv.innerHTML = landTemplate(_land);
    document.getElementById("marketplace").appendChild(newDiv);
  });
}

function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL();

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `;
}

//Land Template
function landTemplate(_land) {
  const endAuctionBtn = `<button type="button" class="btn btn-outline-dark fw-bold endAuction fs-6" id=${_land.index}>
                        End Auction
                        </button>`;
  const bidBtn = `<button type="button" class="btn btn-outline-dark fw-bold bidBtn fs-6" id=${
    _land.index
  }>
    Bid
  </button>`;
  return `
    <div class="card bg-secondary mb-2 text-dark">
      <img class="card-img-top" src="${_land.image}" alt="...">
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_land.owner)}
        </div>
        <div class="translate-middle-y position-relative top-0">
        ${identiconTemplate(_land.highestBidder)}
        </div> 
        <h2 class="card-title fs-4 fw-bold mt-1">${_land.name}</h2>
        <h3 class="card-title fs-6 fw-bold mt-1">Start Bid at ${_land.highestBid
          .shiftedBy(-ERC20_DECIMALS)
          .toFixed(2)} cUSD</h3>
        <div class="d-grid gap-2 ">
          <label for="bidRange" class="form-label">Choose bid range</label>
          <input type="range" class="form-range" min="0" max="10" id="bidRange">
          ${_land.owner != kit.defaultAccount? bidBtn : ""}
          ${_land.owner == kit.defaultAccount? endAuctionBtn : ""}
        </div>
      </div>
    </div>
  `;
}

document
  .querySelector("#connectwallet")
  .addEventListener("click", async (e) => {
    notification("⌛ Loading...");
    await connectCeloWallet();
    await getBalance();
    await getLands();
    if(kit && contract){
      document.querySelector("#connectwallet").classList.add("disabled");
    }
    notificationOff();
  });

function notification(_text) {
  document.querySelector(".alert").style.display = "block";
  document.querySelector("#notification").textContent = _text;
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none";
}

document
  .querySelector("#newProductBtn")
  .addEventListener("click", async (e) => {
    if(!contract && !kit){
      notification("Please connect wallet first to be able to mint land");
      return;
    }
    const params = [
      document.getElementById("newProductName").value,
      document.getElementById("newImgUrl").value,
      new BigNumber(document.getElementById("minPrice").value)
        .shiftedBy(ERC20_DECIMALS)
        .toString(),
    ];
    notification(`⌛ Adding "${params[0]}"...`);
    try {
      const result = await contract.methods
        .CreateAuction(...params)
        .send({ from: kit.defaultAccount });
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notification(`🎉 You successfully added "${params[0]}".`);
    getLands();
    notificationOff();
  });

document.querySelector("#applyList").addEventListener("click", async (e) => {
  let param = document.getElementById("newAddress").value;
   if(!contract && !kit){
     notification("Please connect wallet first to be to add a seller");
     return;
  }
  if(!Web3.utils.isAddress(param)){
    notification("Please enter a valid wallet address");
    return;
  }
  notification(`⌛ Adding "${param}"...`);
  try {
    const result = await contract.methods
      .GiveRightToAuction(param)
      .send({ from: kit.defaultAccount });
    notification(`🎉 You successfully Listed`);
  } catch (error) {
    notification(`⚠️ ${error}.`);
  }
});

document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("bidBtn")) {
    const params = [
      new BigNumber(document.getElementById("bidRange").value)
        .shiftedBy(ERC20_DECIMALS)
        .toString(),
    ];
    const index = e.target.id;
    notification("⌛ Waiting for payment approval...");
    try {
      await approve(...params);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notification(`⌛ Awaiting payment for "${lands[index].name}"...`);
    try {
      const result = await contract.methods
        .MakeBid(index, ...params)
        .send({ from: kit.defaultAccount });
      notification(`🎉 You successfully made a bid "${lands[index].name}".`);
      getLands();
      getBalance();
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  }
});

document.querySelector("#marketplace").addEventListener("click", async (e) => {
  const index = e.target.id;
  if (e.target.className.includes("endAuction") && kit.defaultAccount == lands[index].owner) {
    notification("⌛ please wait...");
    try {
      const result = await contract.methods
        .EndAuction(index)
        .send({ from: kit.defaultAccount });
      notification(`🎉 You successfully ended "${lands[index].name}" auction.`);
      getLands();
      getBalance();
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  }
});
