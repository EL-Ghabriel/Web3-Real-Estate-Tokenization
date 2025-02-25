const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RealEstate Contract - buyProperty function", function () {
  let RealEstate;
  let realEstate;
  let owner;
  let buyer;
  let anotherAccount;
  let propertyId;
  const propertyPrice = ethers.utils.parseEther("1"); // 1 ETH

  beforeEach(async function () {
    // Get contract factory and signers
    RealEstate = await ethers.getContractFactory("RealEstate");
    [owner, buyer, anotherAccount] = await ethers.getSigners();
    
    // Deploy contract
    realEstate = await RealEstate.deploy();
    
    // Add a property for testing
    await realEstate.addProperty(
      propertyPrice,
      "House",
      "house.jpg",
      "123 Main St",
      "Beautiful house"
    );
    
    propertyId = 1; // First property has ID 1
  });

  it("Should allow buying a property with exact price", async function () {
    // Get owner's balance before sale
    const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
    
    // Get all properties to verify initial owner
    const propertiesBefore = await realEstate.getAllProperties();
    expect(propertiesBefore[0].owner).to.equal(owner.address);
    
    // Buy property with exact price
    await expect(
      realEstate.connect(buyer).buyProperty(propertyId, buyer.address, {
        value: propertyPrice
      })
    )
      .to.emit(realEstate, "PropertySold")
      .withArgs(propertyId, owner.address, buyer.address, propertyPrice);
    
    // Get all properties to verify new owner
    const propertiesAfter = await realEstate.getAllProperties();
    expect(propertiesAfter[0].owner).to.equal(buyer.address);
    
    // Verify owner received payment
    const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
    expect(ownerBalanceAfter.sub(ownerBalanceBefore)).to.equal(propertyPrice);
  });

  it("Should allow buying a property with excess funds and refund excess", async function () {
    // Amount to pay (more than the price)
    const paymentAmount = propertyPrice.add(ethers.utils.parseEther("0.5")); // 1.5 ETH
    
    // Get buyer's balance before transaction
    const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);
    
    // Buy property with excess funds
    const tx = await realEstate.connect(buyer).buyProperty(propertyId, buyer.address, {
      value: paymentAmount
    });
    
    // Get transaction receipt to calculate gas used
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);
    
    // Get buyer's balance after transaction
    const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
    
    // Calculate expected balance after transaction
    // Buyer should have spent: property price + gas cost
    const expectedBalance = buyerBalanceBefore
      .sub(propertyPrice)
      .sub(gasUsed);
    
    // Verify buyer received refund (allowing for small rounding/precision differences)
    const balanceDifference = expectedBalance.sub(buyerBalanceAfter).abs();
    expect(balanceDifference).to.be.lt(ethers.utils.parseEther("0.0001")); // Difference should be very small
  });

  it("Should revert when trying to buy with insufficient funds", async function () {
    // Try to buy with less than the price
    const insufficientAmount = propertyPrice.sub(ethers.utils.parseEther("0.1")); // 0.9 ETH
    
    await expect(
      realEstate.connect(buyer).buyProperty(propertyId, buyer.address, {
        value: insufficientAmount
      })
    ).to.be.revertedWith("Insufficient funds");
  });

  it("Should allow a third party to buy property for someone else", async function () {
    // anotherAccount buys property for buyer
    await realEstate.connect(anotherAccount).buyProperty(propertyId, buyer.address, {
      value: propertyPrice
    });
    
    // Verify the property ownership
    const properties = await realEstate.getAllProperties();
    expect(properties[0].owner).to.equal(buyer.address);
  });

  it("Should update the property ownership correctly", async function () {
    // Buy the property
    await realEstate.connect(buyer).buyProperty(propertyId, buyer.address, {
      value: propertyPrice
    });
    
    // Verify the property ownership changed
    const properties = await realEstate.getAllProperties();
    expect(properties[0].owner).to.equal(buyer.address);
    
    // Now the buyer should be able to update the property
    await realEstate.connect(buyer).updateProperty(
      propertyId,
      ethers.utils.parseEther("2"),
      "Updated House",
      "updated.jpg",
      "123 Main St Updated",
      "Updated description",
      true
    );
    
    // Old owner should not be able to update the property anymore
    await expect(
      realEstate.updateProperty(
        propertyId,
        ethers.utils.parseEther("3"),
        "Test",
        "test.jpg",
        "test",
        "test",
        true
      )
    ).to.be.revertedWith("You are not the owner of this property");
  });
});