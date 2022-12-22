// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721 {
    event Transfer(address indexed from, address indexed to, NFT id);
    event Approval(address indexed owner, address indexed spender, uint indexed id);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    struct NFT {
        uint256 id;
        string title; // NFTのTitle
        string url;   // NFTのURL
    }

    // Mapping from token ID to owner address
    mapping(address => NFT[]) internal _ownerOf;

    // Mapping owner address to token count
    mapping(address => uint) internal _balanceOf;

    // Mapping from token ID to approved address
    mapping(uint => address) internal _approvals;

    // @junya
    // isMint
    mapping(address => mapping(uint256 => bool)) public isMint;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function ownerOf(uint id) external view returns (address owner) {}

    function balanceOf(address owner) external view returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balanceOf[owner];
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint id) external {}

    function getApproved(uint id) external view returns (address) {}

    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint id
    ) internal view returns (bool) {
        return (spender == owner ||
            isApprovedForAll[owner][spender] ||
            spender == _approvals[id]);
    }

    function transferFrom(
        address from,
        address to,
        uint id
    ) public {require(from == address(0),"SBT");}

    function safeTransferFrom(
        address from,
        address to,
        uint id
    ) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "") ==
                IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        bytes calldata data
    ) external {
        require(from == address(0),"SBT");

        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) ==
                IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    function _getNFT(address user) public view returns(NFT[] memory nfts_) {
        nfts_ = _ownerOf[user];
    }
    function _mint(uint256 _id, address to,string memory _title,string memory _url) internal {
        require(_id < 3,"ID == only 0,1,2 ");
        require(to != address(0), "mint to zero address");
        if(isMint[msg.sender][_id] == true) revert("Already Minted");
        NFT memory nft = NFT(
            {
                id: _id,
                title:  _title,
                url:    _url
            }
        );


        _balanceOf[to]++;
        _ownerOf[to].push(nft);
        isMint[msg.sender][_id] = true;

        emit Transfer(address(0), to, nft);
    }

    // @junya
    // isMintを確認する
    function checkIsMinted(address user) public view returns(bool[] memory) {
        bool[] memory ret = new bool[](3);
        for(uint i; i < 3; i++) {
            ret[i] = isMint[user][i];
        }
        return ret;
    }
    function _burn(uint id) internal {}
}

contract Web3LearnNFT is ERC721 {


    function mint(uint256 id,address to,string memory _title,string memory _url) external {
        _mint(id, to,_title,_url);
    }

    function getNFT(address user) external view returns(NFT[] memory nfts) {
        nfts = _getNFT(user);
    }

    function getIsMint(address user) external view returns(bool[] memory isMints)  {
        isMints = checkIsMinted(user);
    }
}
