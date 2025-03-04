// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RealEstate {


// STATE VARIABLES
    struct Property {
    uint256 productId;
    mapping(address => uint256) ownershipShares; // Address to percentage (out of 100)
    address[] owners; // List of all owners
    uint256 totalShares; // Total shares issued (e.g., 100 for 100%)
    uint256 price;
    string category;
    string images;
    string propertyAddress;
    string description;
    bool isActive;
}

    struct PropertyView {
        uint256 productId;
        uint256 totalShares;
        uint256 price;
        string category;
        string images;
        string propertyAddress;
        string description;
        bool isActive;
    }

    mapping(uint256 => Property) private properties;
    uint256 public propertyIndex;

    // EVENTS
    event PropertySold(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);
    event PropertyResold(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);

    // FUNCTIONS


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
    propertyIndex++;
    Property storage newProperty = properties[propertyIndex];
    newProperty.productId = propertyIndex;
    newProperty.ownershipShares[msg.sender] = 100; // Give creator 100% initially
    newProperty.owners.push(msg.sender); // Add creator to owners list
    newProperty.totalShares = 100;
    newProperty.price = price;
    newProperty.category = category;
    newProperty.images = images;
    newProperty.propertyAddress = propertyAddress;
    newProperty.description = description;
    newProperty.isActive = true;
}

    function getAllProperties() public view returns (PropertyView[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= propertyIndex; i++) {
            if (properties[i].isActive) {
                activeCount++;
            }
        }

        PropertyView[] memory activeProperties = new PropertyView[](activeCount);
        uint256 j = 0;
        for (uint256 i = 1; i <= propertyIndex; i++) {
            if (properties[i].isActive) {
                activeProperties[j] = PropertyView({
                    productId: properties[i].productId,
                    totalShares: properties[i].totalShares,
                    price: properties[i].price,
                    category: properties[i].category,
                    images: properties[i].images,
                    propertyAddress: properties[i].propertyAddress,
                    description: properties[i].description,
                    isActive: properties[i].isActive
                });
                j++;
            }
        }
        return activeProperties;
    }

    function getOwnershipShares(uint256 productId, address user) public view returns (uint256) {
        require(productId > 0 && productId <= propertyIndex, "Invalid Property ID");
        return properties[productId].ownershipShares[user];
    }


    function getPropertyOwners(uint256 productId) public view returns (address[] memory, uint256[] memory) {
    require(productId > 0 && productId <= propertyIndex, "Invalid Property ID");
    
    Property storage property = properties[productId];
    uint256 ownerCount = property.owners.length;
    
    address[] memory ownerAddresses = new address[](ownerCount);
    uint256[] memory ownerShares = new uint256[](ownerCount);
    
    for (uint256 i = 0; i < ownerCount; i++) {
        ownerAddresses[i] = property.owners[i];
        ownerShares[i] = property.ownershipShares[property.owners[i]];
    }
    
    return (ownerAddresses, ownerShares);
}



//BUY PROPERTY
function buyProperty(uint256 productId, uint256 sharesToBuy, address seller) external payable {
    require(productId > 0 && productId <= propertyIndex, "Invalid Property ID");
    require(sharesToBuy > 0 && sharesToBuy <= 100, "Shares must be between 1 and 100");
    Property storage property = properties[productId];
    require(sharesToBuy <= property.ownershipShares[seller], "Not enough shares available from seller");

    uint256 sharePrice = (property.price * sharesToBuy) / 100;
    require(msg.value >= sharePrice, "Insufficient funds");

    address buyer = msg.sender;
    bool isNewOwner = property.ownershipShares[buyer] == 0;

    property.ownershipShares[seller] -= sharesToBuy;
    property.ownershipShares[buyer] += sharesToBuy;
    if (isNewOwner) {
        property.owners.push(buyer);
    }

    (bool sent,) = payable(seller).call{value: sharePrice}("");
    require(sent, "Payment to seller failed");

    uint256 excessAmount = msg.value - sharePrice;
    if (excessAmount > 0) {
        (bool refunded,) = payable(buyer).call{value: excessAmount}("");
        require(refunded, "Refund failed");
    }

    emit PropertySold(productId, seller, buyer, sharePrice);
}


function updateProperty(
    uint256 productId, 
    uint256 newPrice, 
    string memory newCategory, 
    string memory newImages, 
    string memory newPropertyAddress, 
    string memory newDescription, 
    bool newActiveStatus
) external {
    require(productId > 0 && productId <= propertyIndex, "Invalid Property ID");
    require(properties[productId].ownershipShares[msg.sender] > 0, "You are not a shareholder");

    Property storage property = properties[productId];
    property.price = newPrice;
    property.category = newCategory;
    property.images = newImages;
    property.propertyAddress = newPropertyAddress;
    property.description = newDescription;
    property.isActive = newActiveStatus;
}



function getUserProperties(address user) public view returns (PropertyView[] memory) {
    uint256 userPropertyCount = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].ownershipShares[user] > 0 && properties[i].isActive) {
            userPropertyCount++;
        }
    }

    PropertyView[] memory userProperties = new PropertyView[](userPropertyCount);
    uint256 currentIndex = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].ownershipShares[user] > 0 && properties[i].isActive) {
            userProperties[currentIndex] = PropertyView({
                productId: properties[i].productId,
                totalShares: properties[i].totalShares,
                price: properties[i].price,
                category: properties[i].category,
                images: properties[i].images,
                propertyAddress: properties[i].propertyAddress,
                description: properties[i].description,
                isActive: properties[i].isActive
            });
            currentIndex++;
        }
    }
    return userProperties;
}




function ownedProperties() public view returns (PropertyView[] memory) {
    uint256 ownedCount = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].ownershipShares[msg.sender] > 0) {
            ownedCount++;
        }
    }

    PropertyView[] memory ownedProps = new PropertyView[](ownedCount);
    uint256 currentIndex = 0;
    for (uint256 i = 1; i <= propertyIndex; i++) {
        if (properties[i].ownershipShares[msg.sender] > 0) {
            ownedProps[currentIndex] = PropertyView({
                productId: properties[i].productId,
                totalShares: properties[i].totalShares,
                price: properties[i].price,
                category: properties[i].category,
                images: properties[i].images,
                propertyAddress: properties[i].propertyAddress,
                description: properties[i].description,
                isActive: properties[i].isActive
            });
            currentIndex++;
        }
    }
    return ownedProps;
}


}
