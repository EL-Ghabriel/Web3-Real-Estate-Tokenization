const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RealEstate Contract", function () {
  let RealEstate;
  let realEstate;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    // Get the contract factory and signers
    RealEstate = await ethers.getContractFactory("RealEstate");
    [owner, addr1, addr2] = await ethers.getSigners();
    
    // Deploy the contract
    realEstate = await RealEstate.deploy();
  });

  it("Should add a new property", async function () {
    const price = 100;
    const category = "House";
    const images = "house.jpg";
    const propertyAddress = "123 Main St";
    const description = "Beautiful house";
    
    // Add the property - with the correct parameter count
    await realEstate.addProperty(price, category, images, propertyAddress, description);
    
    const properties = await realEstate.getAllProperties();
    expect(properties.length).to.equal(1);
    expect(properties[0].price).to.equal(price);
  });

  it("Should update a property", async function () {
    const price = 100;
    const category = "House";
    const images = "house.jpg";
    const propertyAddress = "123 Main St";
    const description = "Beautiful house";
    
    // Add a property first
    await realEstate.addProperty(price, category, images, propertyAddress, description);
    
    const newPrice = 200;
    await realEstate.updateProperty(1, newPrice, "Apartment", "apartment.jpg", "456 Oak St", "Beautiful apartment", true);

    const properties = await realEstate.getAllProperties();
    expect(properties[0].price).to.equal(newPrice);
  });

  it("Should only allow the owner to update a property", async function () {
    const price = 100;
    const category = "House";
    const images = "house.jpg";
    const propertyAddress = "123 Main St";
    const description = "Beautiful house";
    
    // Add a property first
    await realEstate.addProperty(price, category, images, propertyAddress, description);
    
    // Try to update by another address
    await expect(realEstate.connect(addr1).updateProperty(1,100 , "", "", "", "", false))
      .to.be.revertedWith("You are not the owner of this property");
  });
});