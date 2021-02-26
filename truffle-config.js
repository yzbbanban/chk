module.exports = {
    compilers: {
        solc: {
            version: "0.6.2", // A version or constraint - Ex. "^0.5.0"
            // Can also be set to "native" to use a native solc
            parser: "solcjs", // Leverages solc-js purely for speedy parsing
        }
    },
    networks: {
        development: {
           host: "mainnet-rpc.com",    
           port: 80, 
           gas:10000000,
           network_id: "*",  
           type: "conflux",     
        //    privateKeys: [""], 
        },
        wtest: {
          host: "wallet-test.confluxrpc.org",
          port: 80,
          network_id: "10001",
          gas:10000000,
          type: "conflux",
        //   privateKeys: [""], 
        }
       }
}
