// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Store is Ownable {

    uint256 totalRevenue;
    /// @notice buyer => product_id => quantity
    mapping(address => mapping(uint256 => uint256)) public userPurchase;
    /// @notice product_id => quantity
    mapping(uint256 => uint256) public productsPurchase;
    /// @notice buyer => Purchase
    mapping(address => Purchase[]) public Purchases;
    /// @notice discountCode => discountAmount
    mapping(string => uint256) public discountCodes;

    struct Product {
        string name;
        uint256 id;
        uint256 stock;
        uint256 price;
    }

    struct Purchase {
        uint256 productId;
        uint256 quantity;
        uint256 paidPrice;
        uint256 timestamp;
    }

    Product[] private products;

    error IdAlreadyExist();
    error IdDoesNotExist();
    error OutOfStock();
    error NotEnoughtMoney();
    error IncorrectData();
    error CantRefundAfter24h();
    error InvalidDiscountAmount();
    error DiscountAlreadyExist();

    event PurchaseMade(address buyer, uint256 id, uint256 quantity, uint256 paidPrice);
    event ReturnMade(address buyer, uint256 id, uint256 quantity, uint256 returnPrice);

    constructor() Ownable(msg.sender) {}

    function buy(uint256 _id, uint256 _quantity, string calldata _discountCode) payable  external {
        require(getStock(_id) >= _quantity, OutOfStock());

        uint256 discount = discountCodes[_discountCode];
        uint256 cost = getPrice(_id)*_quantity;

        if (discount > 0){
            cost = cost*(1-discount/100);
        }

        require(msg.value >= cost, NotEnoughtMoney());

        _buyProcess(msg.sender, _id, _quantity, cost);

        if(msg.value > cost){
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function batchBuy(uint256[] calldata _ids, uint256[] calldata _quantities, string calldata _discountCode) payable  external {
        require(_ids.length == _quantities.length, IncorrectData());
        uint256 cost;

        for (uint i = 0; i < _ids.length; i++){
            require(_quantities[i] > 0, IncorrectData());
            require(getStock(_ids[i]) >= _quantities[i], OutOfStock());

            cost += _quantities[i]*getPrice(_ids[i]);
        }

        uint256 discount = discountCodes[_discountCode];
        if (discount > 0){
            cost = cost*(1-discount/100);
        }

        require(msg.value >= cost, NotEnoughtMoney());

        for (uint i = 0; i < _ids.length; i++){
            _buyProcess(msg.sender, _ids[i], _quantities[i], cost);
        }

        if(msg.value > cost){
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function _buyProcess(address buyer, uint256 _id, uint256 _quantity, uint256 _paidPrice) internal {
        Product storage product = findProduct(_id);
        product.stock -= _quantity;
        totalRevenue += _paidPrice;

        userPurchase[msg.sender][_id] += _quantity;
        productsPurchase[_id] += _quantity;

        Purchases[buyer].push(Purchase(_id, _quantity, _paidPrice, block.timestamp));

        emit PurchaseMade(buyer, _id, _quantity, _paidPrice);
    }

    function withdraw() external  onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, NotEnoughtMoney());
        payable (owner()).transfer(balance);
    }

    function refund() public {
        require(Purchases[msg.sender].length > 0, IncorrectData());
        
        uint256 lastIndex = Purchases[msg.sender].length - 1;
        Purchase storage lastPurchase = Purchases[msg.sender][lastIndex];
        Product storage product = findProduct(lastPurchase.productId);

        require(block.timestamp - lastPurchase.timestamp <= 1 days, CantRefundAfter24h());
        require(address(this).balance >= lastPurchase.paidPrice,NotEnoughtMoney());

        userPurchase[msg.sender][lastPurchase.productId] -= lastPurchase.quantity;
        productsPurchase[lastPurchase.productId] -= lastPurchase.quantity;
        totalRevenue -= lastPurchase.paidPrice;
        product.stock += lastPurchase.quantity;

        payable(msg.sender).transfer(lastPurchase.paidPrice);

        emit ReturnMade(msg.sender, lastPurchase.productId, lastPurchase.quantity, lastPurchase.paidPrice);

        Purchases[msg.sender].pop();
    }

    function addProduct(string calldata _name, uint256 _id, uint _stock, uint256 _price) external onlyOwner {
        require(!isIdExist(_id), IdAlreadyExist());
        products.push(Product(_name, _id, _stock, _price));
    }

    function addDiscountCode(string calldata code, uint256 discountAmount) external onlyOwner{
        require(discountAmount > 0 && discountAmount <= 90, InvalidDiscountAmount());
        require(discountCodes[code] == 0,DiscountAlreadyExist());

        discountCodes[code] = discountAmount;
    }

    function deleteDiscountCode(string calldata code) external onlyOwner{
        require(discountCodes[code] > 0, IncorrectData());

        delete discountCodes[code];
    }

    function deleteProduct(uint256 _id) external onlyOwner {
        (bool status, uint256 index)  = findIndexById(_id);
        require(status, IdDoesNotExist());
        products[index] = products[products.length-1];
        products.pop();
    }

    function updatePrice(uint256 _id, uint256 _price) external onlyOwner {
        Product storage product = findProduct(_id);
        product.price = _price;
    }

    function updateStock(uint256 _id, uint256 _stock) external onlyOwner {
        Product storage product = findProduct(_id);
        product.stock = _stock;
    }

    function getTopSellingProduct() public view returns(uint256 topSellingProduct, uint256 topSales) {
        require(products.length > 0, IncorrectData());
        
        topSales;
        topSellingProduct = products[0].id;

        for (uint i = 0; i < products.length; i++){

            uint256 productId = products[i].id;
            uint256 sales = productsPurchase[productId];

            if (sales > topSales){
                topSales = sales;
                topSellingProduct = productId;
            }
        }

        return (topSellingProduct, topSales);
    }

    function getProducts() public view returns(Product[] memory) {
        return products;
    }

    function getUserPurchases(address buyer) public view returns(Purchase[] memory){
        return Purchases[buyer];
    }

    function getPrice (uint256 _id) public view returns(uint256) {
        Product storage product = findProduct(_id);
        return product.price;
    }

    function getStock (uint256 _id) public view returns(uint256) {
        Product storage product = findProduct(_id);
        return product.stock;
    }

    function getTotalRevenue () public view returns(uint256) {
        return totalRevenue;
    }

    function findProduct(uint256 _id) internal view returns(Product storage product) {
        for(uint i = 0; i < products.length; i++) {
            if(products[i].id == _id){
                return products[i];
            }
        }
        revert IdDoesNotExist();
    }

    function isIdExist(uint256 _id) internal view returns(bool) {
        for(uint i=0; i < products.length; i++) {
            if(products[i].id == _id){
                return true;
            }
        }
        return false;
    }

    function findIndexById(uint256 _id) internal view returns(bool, uint256) {
        for(uint i = 0; i < products.length; i++) {
            if(products[i].id == _id) {
                return (true, i);
            }
        }
        return (false, 0);
    }

}