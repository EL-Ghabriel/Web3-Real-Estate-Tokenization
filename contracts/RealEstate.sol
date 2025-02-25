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

    //EVENTS

    event PropertySold(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);
    event PropertyResold(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);


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


function buyProperty(uint256 productId, address buyer) external payable {
    uint256 amount = msg.value;
    require(amount >= properties[productId].price, "Insufficient funds");
    
    Property storage property = properties[productId];
    address oldOwner = property.owner; // Store old owner before updating
    uint256 propertyPrice = property.price; // Store price to avoid multiple storage reads
    
    // Update the property owner before sending funds to avoid reentrancy issues
    property.owner = buyer;
    
    // Transfer only the property price to the old owner
    (bool sent,) = payable(oldOwner).call{value: propertyPrice}("");
    require(sent, "Payment to the owner failed");

    // Refund the excess amount back to the sender
    uint256 excessAmount = amount - propertyPrice;
    if (excessAmount > 0) {
        (bool refunded,) = payable(msg.sender).call{value: excessAmount}("");
        require(refunded, "Refund failed");
    }
    
    // Emit event with correct oldOwner, newOwner, and price
    emit PropertySold(productId, oldOwner, buyer, propertyPrice);
}





// function get userProperties() 
// function getProperty() 



}
