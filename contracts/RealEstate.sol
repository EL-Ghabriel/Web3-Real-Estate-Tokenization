// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RealEstate {



    //STATE VARIABLE

    struct Property{
        uint256 productId;
        address owner;
        uint256 price;
        string category;
        string images;
        string propertyAddress;
        string description;
        bool isActive;
    }

    // MAPPING
    mapping(uint256 => Property) private properties;
    uint256 public propertyIndex;



    // FONCTIONS IN CONTRACT

function listNumberOfProperty() external view returns (uint256) {
    uint256 activeCount = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].isActive) {
            activeCount++;
        }
    }
    return activeCount;
}



function addProperty(
    uint256 price,
    string memory category,
    string memory images,
    string memory propertyAddress,
    string memory description
) external {
    propertyIndex++; // Increment first, so productId starts at 1
    properties[propertyIndex] = Property({
        productId: propertyIndex,
        owner: msg.sender,
        price: price,
        category: category,
        images: images,
        propertyAddress: propertyAddress,
        description: description,
        isActive: true
    });
}

    function updateProperty(
        uint256 productId, 
        uint256 newPrice, 
        string memory newCategory, 
        string memory newImages, 
        string memory newPropertyAddress, 
        string memory newDescription, 
        bool newActiveStatus) external {

        require(productId > 0 && productId <= propertyIndex, "Invalid Property ID");
        require(msg.sender == properties[productId].owner, "You are not the owner of this property");

        properties[productId].price = newPrice;
        properties[productId].category = newCategory;
        properties[productId].images = newImages;
        properties[productId].propertyAddress = newPropertyAddress;
        properties[productId].description = newDescription;
        properties[productId].isActive = newActiveStatus;
    }




function getAllProperties() public view returns (Property[] memory) {
    uint256 activeCount = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].isActive) {
            activeCount++;
        }
    }

    Property[] memory activeProperties = new Property[](activeCount);
    uint256 j = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].isActive) {
            activeProperties[j] = properties[i];
            j++;
        }
    }
    return activeProperties;
}



}
