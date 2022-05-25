import Web3 from "web3";
import { newKitFromWeb3 } from "@celo/contractkit";
import BigNumber from "bignumber.js";
import erc20Abi from "../contract/erc20.abi.json";
import seloWorldAbi from "../contract/seloWorld.abi.json";

const ERC20_DECIMALS = 18;
//crypto zombies changing contract logic
const MPContractAddress = "0xB2de9Ea878e01C54B01eAbdD7b3F2ff4c64628a5";
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

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress);
  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount });
  return result;
}

const getLands = async function () {
  const _landsLength = await contract.methods.getLandsLength().call();
  const _lands = [];

  for (let i = 0; i < _landsLength; i++) {
    let _land = new Promise(async (resolve, reject) => {
      let p = await contract.methods.readLand(i).call();
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        streetName: p[3],
        price: new BigNumber(p[4]),
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
  return `
    <div class="card bg-secondary mb-3 text-dark">
      <img class="card-img-top" src="${_land.image}" alt="...">
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_land.owner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">${_land.name}</h2>
        <h3 class="card-title fs-5 fw-bold mt-1">${_land.streetName}</h3>
        <div class="d-grid gap-2 ">
          <a class="btn btn-lg btn-outline-dark buyBtn fs-6 p-3" id=${
            _land.index
          }>
            Start bid at ${_land.price
              .shiftedBy(-ERC20_DECIMALS)
              .toFixed(2)} cUSD
          </a>
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
    const params = [
      document.getElementById("newProductName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newStreetName").value,
      new BigNumber(document.getElementById("newPrice").value)
        .shiftedBy(ERC20_DECIMALS)
        .toString(),
    ];
    notification(`⌛ Adding "${params[0]}"...`);
    try {
      const result = await contract.methods
        .writeLand(...params)
        .send({ from: kit.defaultAccount });
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notification(`🎉 You successfully added "${params[0]}".`);
    getLands();
    notificationOff();
  });

document.querySelector("#applyList").addEventListener("click", async (e) => {
  const params = [document.getElementById("newAddress").value];
  notification(`⌛ Adding "${params[0]}"...`);
  try {
    const result = await contract.methods
      .giveRightToWriteLand(...params)
      .send({ from: kit.defaultAccount });
  } catch (error) {
    notification(`⚠️ ${error}.`);
  }
  notification(`🎉 You successfully Listed`);
});

document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("buyBtn")) {
    const index = e.target.id;
    notification("⌛ Waiting for payment approval...");
    try {
      await approve(lands[index].price);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notification(`⌛ Awaiting payment for "${lands[index].name}"...`);
    try {
      const result = await contract.methods
        .buyLand(index)
        .send({ from: kit.defaultAccount });
      notification(`🎉 You successfully bought "${lands[index].name}".`);
      getLands();
      getBalance();
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  }
});

document.querySelector("").addEventListener("click", async (e) => {});
