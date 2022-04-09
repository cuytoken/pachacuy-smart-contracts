1. Los precios de las rarezas se deben setear antes empezar la compra. Para ello se ha definido una function que permite poner el precio a cada rareza.

Se utilizará la siguiente lista para poner el precio:

// Price whtn purchase by using an ID
uint256 public explorerPrice; // 1 - "EXPLORADOR"
uint256 public phenomenoPrice; // 2 - "FENOMEMO"
uint256 public mysticPrice; // 3 - "MISTICO"
uint256 public legendaryPrice; // 4 - "LEGENDARIO"
uint256 public mandingoPrice; // 5 - "MANDINGO

La siguiente función recibe 2 parámetros: índice y precio:

- índice corresponde a 1, 2, 3, 4 o 5
- precio es la nueva cantidad del costo

function setPriceOfRarity(uint256 ixRarity, uint256 price) public;
