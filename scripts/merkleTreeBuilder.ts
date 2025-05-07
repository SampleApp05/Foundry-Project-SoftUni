import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";
import { ethers } from "hardhat";

// (1)
const users = [
  {
    address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111111",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111112",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111113",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111114",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111115",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111116",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111117",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111118",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111119",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111120",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111121",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111122",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111123",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111124",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111125",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111126",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111127",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111128",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111129",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0x1111111111111111111111111111111111111130",
    maxTokens: ethers.parseEther("50000"),
  },
  {
    address: "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
    maxTokens: ethers.parseEther("25000"),
  },
];

let usersData = users.map((user) => {
  return [user.address, user.maxTokens.toString()];
});

let tree = StandardMerkleTree.of(usersData, ["address", "uint256"]);

let data = Array.from(tree.entries()).map((item, index) => {
  let userID = index >= 20 ? 256 + (index % 20) : index; // mocking large data set
  if (index == 0) {
    console.log(
      "Item data -----------------------------------------------------"
    );
    console.log(item);
    console.log(tree.getProof(item[0]));
    console.log(
      "Item data end -----------------------------------------------------"
    );
  }

  return {
    userID: index,
    address: item[1][0],
    maxTokens: item[1][1],
    proof: tree.getProof(item[0]),
  };
});

let fileContent = {
  root: tree.root,
  data: data,
};

fs.writeFileSync("merkleTreeProof.json", JSON.stringify(fileContent, null, 2));
