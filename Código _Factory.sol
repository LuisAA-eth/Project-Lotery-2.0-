//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Fabrica de smartcontracts

contract Factory {
    mapping (address =>address) public user_contract;
    function factory() public  {
        address secondContract = address (new Contrato(msg.sender, address(this)));
        user_contract[msg.sender]=secondContract;
    }
}

contract Contrato {
    struct Datos {
        address owner;
        address padre;
    }

    Datos public datos;
    constructor(address _owner, address _padre){
        datos.owner = _owner;
        datos.padre = _padre;
    }
}