// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Nft is ERC721URIStorage {
    using Strings for uint256;
    uint currentTokenId;

    mapping(uint256 => uint256) public tokenIdToLevels;

    constructor() ERC721("Z_Breed", "Z-B") {}

    function generateCharacter(
        uint256 tokenId
    ) public view returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="256" height="256" viewBox="0 0 256 256" xml:space="preserve">'
            "<defs>"
            "</defs>"
            '<g style="stroke: none; stroke-width: 0; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: none; fill-rule: nonzero; opacity: 1;" transform="translate(1.4065934065934016 1.4065934065934016) scale(2.81 2.81)" >'
            '<path d="M 45 0 C 20.147 0 0 20.147 0 45 s 20.147 45 45 45 s 45 -20.147 45 -45 S 69.853 0 45 0 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(248,195,65); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />'
            '<path d="M 45 10 c -19.33 0 -35 15.67 -35 35 s 15.67 35 35 35 s 35 -15.67 35 -35 S 64.33 10 45 10 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(206,140,0); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />'
            '<polygon points="73.42,18.09 78.94,19.85 74.48,23.55 72.72,29.07 69.02,24.61 63.5,22.84 67.96,19.14 69.72,13.63 " style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,237,154); fill-rule: nonzero; opacity: 1;" transform="  matrix(1 0 0 1 0 0) "/>'
            '<polygon points="81.31,35.82 83.27,38.73 79.76,38.81 76.85,40.77 76.77,37.26 74.81,34.35 78.32,34.27 81.24,32.31 " style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,237,154); fill-rule: nonzero; opacity: 1;" transform="  matrix(1 0 0 1 0 0) "/>'
            '<path d="M 33.962 34.507 c -1.291 0 -2.339 1.047 -2.339 2.339 v 8.107 l -5.798 -9.341 c -0.55 -0.888 -1.621 -1.3 -2.628 -1.016 c -1.004 0.287 -1.697 1.205 -1.697 2.249 v 16.31 c 0 1.292 1.047 2.339 2.339 2.339 c 1.291 0 2.339 -1.047 2.339 -2.339 v -8.107 l 5.798 9.341 c 0.434 0.7 1.193 1.105 1.987 1.105 c 0.213 0 0.429 -0.029 0.641 -0.09 c 1.004 -0.286 1.697 -1.204 1.697 -2.249 v -16.31 C 36.3 35.554 35.253 34.507 33.962 34.507 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(248,195,65); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />'
            '<path d="M 49.332 39.184 c 1.292 0 2.339 -1.047 2.339 -2.339 c 0 -1.291 -1.047 -2.339 -2.339 -2.339 h -6.486 c -1.291 0 -2.339 1.047 -2.339 2.339 v 16.31 c 0 1.292 1.047 2.339 2.339 2.339 s 2.339 -1.047 2.339 -2.339 v -5.816 h 4.148 c 1.292 0 2.339 -1.047 2.339 -2.339 c 0 -1.291 -1.047 -2.339 -2.339 -2.339 h -4.148 v -3.478 H 49.332 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(248,195,65); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />',
            getLevels(tokenId),
            '<path d="M 66.161 34.507 h -9.269 c -1.292 0 -2.339 1.047 -2.339 2.339 c 0 1.291 1.047 2.339 2.339 2.339 h 2.296 v 13.971 c 0 1.292 1.047 2.339 2.339 2.339 s 2.339 -1.047 2.339 -2.339 V 39.184 h 2.296 c 1.292 0 2.339 -1.047 2.339 -2.339 C 68.5 35.554 67.453 34.507 66.161 34.507 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(248,195,65); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />'
            "</g>"
            "</svg>"
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    function getLevels(uint256 tokenId) public view returns (string memory) {
        uint256 levels = tokenIdToLevels[tokenId];
        return levels.toString();
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Z-BREED #',
            tokenId.toString(),
            '",',
            '"description": "Battles on chain",',
            '"image": "',
            generateCharacter(tokenId),
            '"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function mint() public {
        currentTokenId = currentTokenId + 1;

        // uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId);
        tokenIdToLevels[currentTokenId] = 0;
        _setTokenURI(currentTokenId, getTokenURI(currentTokenId));
    }
}
