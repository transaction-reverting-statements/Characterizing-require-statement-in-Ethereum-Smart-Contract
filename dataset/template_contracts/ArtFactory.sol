pragma solidity ^0.4.15;

// ArtFactory
//
// The core contract that the client interacts with to manage artists and their uploaded content.
contract ArtFactory {

    struct Content{
        string videoUrl;
        string thumbnailUrl;
        string title;
        string description;
        uint128 price;
        mapping(address => bool) viewingAllowed;
    }

    struct Artist{
        string nickname;
        string email;
        address artistAddress;
        // Content[] contents;
    }

    address public owner;
    address[] public artists;
    mapping(address => Artist) public artistMapping;
    mapping(address => bool) public signedUp;
    mapping(address => Content[]) public contentsMapping;
    mapping(address => uint) public balances;

    modifier notSignedUp {
        require(!signedUp[msg.sender]);
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    // createArtist       Create a new Artist contract and update state variables
    // @param _nickname   The nickname of the Artist
    // @param _email      The email of the artist
    //
    // @return address    Returns the address of the new Artist contract
    function createArtist(string _nickname, string _email) public notSignedUp returns (bool){
        // Content[] memory emptyContents;
        Artist memory artist = Artist(_nickname, _email, msg.sender);//, emptyContents);
        // Might be unnecessary to store an array of Artists unless we want to
        // list some of these artists on the client
        artists.push(msg.sender);

        // Set the address as signed up
        signedUp[msg.sender] = true;
        artistMapping[msg.sender] = artist;

        return true;
    }

    // NewContent            Create a new Content contract and update state variables
    // @param _videoUrl      The IPFS url of the video
    // @param _thumbnailUrl  The IPFS url of the thumbnail
    // @param _title         The content title
    // @param _description   The content description
    // @param _price         The price that supporters will have to pay to access the content
    //
    // @return address       Returns the address of the new Content contract
    function createContent(
        string _videoUrl,
        string _thumbnailUrl,
        string _title,
        string _description,
        uint128 _price)
        public returns (bool) {
            Content memory content = Content(_videoUrl, _thumbnailUrl, _title, _description, _price);

            // Store the content in an array so we can access all of an artist's content

            contentsMapping[msg.sender].push(content);
            // Artist storage artist = artistMapping[msg.sender];
            // artist.contents.push(content);

            return true;
    }
    // TODO: Implement the following
    //function viewBalance()
    //function withdraw()
}

