/* 
   QR code generator
   When placed in QRcodeGenerator.oxp, listens for a linkmessage
   and generates a QR code from it.
   Uses QRcodeGenTexture.png which must be in the object's inventory
   
   Adapted from a script by (I think) Fig Mistwood @ secondlife
*/

string texture;
integer WHITE = 0;
integer BLACK = 1;
string JIS8 = "???????????????????????????????? !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[?]^_`abcdefghijklmnopqrstuvwxyz{|}?";
//"  this comment fixes notepad++'s syntax highlighting, which got confused by
//   the escaped quotes above.
string ZEROES = "0000000000000000";
string MODE_DATA = "0100";
string FORMAT_DATA_7L = "111011111000100";
string VERSION_DATA_7 = "000111110010010100";
integer NUM_DATA_BITS = 1248;
integer NUM_DATA_CODEWORDS = 156;
integer NUM_EC_CODEWORDS = 40;
string S_GENERATOR_POLYNOMIAL_AN_20 = "190,188,212,212,164,156,239,083,225,221,180,202,187,026,163,061,050,079,060,017,000,";
string S_GF256_TO_INT = "001,002,004,008,016,032,064,128,029,058,116,232,205,135,019,038,076,152,045,090,180,117,234,201,143,003,006,012,024,048,096,192,157,039,078,156,037,074,148,053,106,212,181,119,238,193,159,035,070,140,005,010,020,040,080,160,093,186,105,210,185,111,222,161,095,190,097,194,153,047,094,188,101,202,137,015,030,060,120,240,253,231,211,187,107,214,177,127,254,225,223,163,091,182,113,226,217,175,067,134,017,034,068,136,013,026,052,104,208,189,103,206,129,031,062,124,248,237,199,147,059,118,236,197,151,051,102,204,133,023,046,092,184,109,218,169,079,158,033,066,132,021,042,084,168,077,154,041,082,164,085,170,073,146,057,114,228,213,183,115,230,209,191,099,198,145,063,126,252,229,215,179,123,246,241,255,227,219,171,075,150,049,098,196,149,055,110,220,165,087,174,065,130,025,050,100,200,141,007,014,028,056,112,224,221,167,083,166,081,162,089,178,121,242,249,239,195,155,043,086,172,069,138,009,018,036,072,144,061,122,244,245,247,243,251,235,203,139,011,022,044,088,176,125,250,233,207,131,027,054,108,216,173,071,142,001,";
string S_GF256_TO_AN = "-01,000,001,025,002,050,026,198,003,223,051,238,027,104,199,075,004,100,224,014,052,141,239,129,028,193,105,248,200,008,076,113,005,138,101,047,225,036,015,033,053,147,142,218,240,018,130,069,029,181,194,125,106,039,249,185,201,154,009,120,077,228,114,166,006,191,139,098,102,221,048,253,226,152,037,179,016,145,034,136,054,208,148,206,143,150,219,189,241,210,019,092,131,056,070,064,030,066,182,163,195,072,126,110,107,058,040,084,250,133,186,061,202,094,155,159,010,021,121,043,078,212,229,172,115,243,167,087,007,112,192,247,140,128,099,013,103,074,222,237,049,197,254,024,227,165,153,119,038,184,180,124,017,068,146,217,035,032,137,046,055,063,209,091,149,188,207,205,144,135,151,178,220,252,190,097,242,086,211,171,020,042,093,158,132,060,057,083,071,109,065,162,031,045,067,216,183,123,164,118,196,023,073,236,127,012,111,246,108,161,059,082,041,157,085,170,251,096,134,177,187,204,062,090,203,089,095,176,156,169,160,081,011,245,022,235,122,117,044,215,079,174,213,233,230,231,173,232,116,214,244,234,168,080,088,175,";

string FACES = "37461";
float HORIZ_UNIT = 0.34375;
float VERT_UNIT = 0.00390625;
list HORIZ_REPEATS = [0.6975, 0.28125, -4.73203125, 0.28125, 0.6975];
list HORIZ_OFFSETS = [-0.0865, -0.296875, -0.308, -0.296875, -0.505625];
float VERT_REPEAT = 0.000;
float VERT_OFFSET = 0.498046875;

integer TEX_ROWS = 256;
integer TEX_COLS = 2;

string qrMatrix;

integer listenID;

// Progress text
string encodingText;
float errorProgress;
string errorText;
string imageText;

updateProgress() {
     llSetText(encodingText
                 + errorText
                 + imageText,
                 ZERO_VECTOR, 1.0);
}

integer binToDec(string _val) {
    string temp = "0" + _val;
    integer dec = 0;
    integer i = ~llStringLength(temp);
    while(++i)
        dec = (dec << 1) + (integer)llGetSubString(temp, i, i);
    return dec;
}

string decTo8BitBin(integer _val) {
    string binary = (string)(_val & 1);
    integer counter = 0;
    for(_val = ((_val >> 1) & 0x7FFFFFFF); counter < 7; _val = (_val >> 1))
    {
        if (_val & 1)
            binary = "1" + binary;
        else
            binary = "0" + binary;
        counter++;
    }
    return binary;
}

list convertToIntegers(list _alpha_notation) {
    list result = [];
    integer length = llGetListLength(_alpha_notation);
    integer i;
    for(i = length - 1; i >= 0; i--) {
        if(llList2Integer(_alpha_notation, i) == -1)
            result = [0] + result;
        else {
            integer index = llList2Integer(_alpha_notation, i);
            result = [(integer)llGetSubString(S_GF256_TO_INT, index * 4, (index * 4) + 2)] + result;
        }
    }
    return result;
}

list convertToAlphaNotation(list _integers) {
    list result = [];
    integer length = llGetListLength(_integers);
    integer i;
    for(i = length - 1; i >= 0; i--) {
        integer index = llList2Integer(_integers, i);
        result = [(integer)llGetSubString(S_GF256_TO_AN, index * 4, (index * 4) + 2)] + result;
    }
    return result;
}

string encode8BitByte(string _message) {
    string result = "";
    integer length = llStringLength(_message);

    // Progress update amount
    integer thirds = length / 3;

    integer i;
    integer encodingProgress = -30;
    for(i = 0; i < length; i++) {
        result += decTo8BitBin(llSubStringIndex(JIS8, llGetSubString(_message, i, i)));
        if(i % thirds == 0) {
            encodingProgress += 30;
            encodingText = "Encoding text: " + (string) encodingProgress + "%\n";
            updateProgress();
        }
    }
    encodingText = "Encoding text: 100%\n";
    return result;
}

string generateDataStream(string _message) {
    integer messageLength = llStringLength(_message);
    if(messageLength > 154) {
        string charText = "characters";
        if(messageLength == 155)
            charText = "character";
        llOwnerSay("Sorry, your text had " + (string) (messageLength - 154) + " more " + charText + " than the maximum.");
        llResetScript();
    }
    string dataStream = MODE_DATA + (decTo8BitBin(messageLength)) + encode8BitByte(_message);
    integer dsLength = llStringLength(dataStream);
    // Check that character limit has not been exceeded
    if(dsLength > NUM_DATA_BITS) {
        llOwnerSay("Sorry, that text had too many characters. Max is 154.");
        llResetScript();
    }
    // Add terminator if necessary
    if(dsLength < NUM_DATA_BITS - 3)
        dataStream += "0000";
    else if(dsLength != NUM_DATA_BITS)
        dataStream += llGetSubString(ZEROES, 0, (NUM_DATA_BITS - dsLength) - 1);
    // Pad the last codeword if necessary
    integer codewordPaddingLength = llStringLength(dataStream) % 8;
    if(codewordPaddingLength != 0)
        dataStream += llGetSubString(ZEROES, 0, codewordPaddingLength - 1);
    // Add pad codewords if necessary
    integer remainingCodewords = (integer)((NUM_DATA_BITS - llStringLength(dataStream)) * 0.125);
    integer i;
    for(i = 0; i < remainingCodewords; i++) {
        if(i % 2 == 0)
            dataStream += "11101100";
        else
            dataStream += "00010001";
    }
    return dataStream;
}

// Input - bit stream of codewords
// Output - bit stream of 20 error correction codewords
string generateErrorCorrectionStream(string _data_stream, integer _num_codewords) {
    string result = "";
    list resultArray = [];
    integer dsLength = llStringLength(_data_stream);
    integer counter = 0;
    integer i;
    for(i = 0; i < dsLength; i += 8) {
        resultArray = [binToDec(llGetSubString(_data_stream, i, i + 7))] + resultArray;
        counter++;
    }

    // Progress update amount
    float progressDelta = 0.641;

    while(counter < _num_codewords) {
        resultArray = [0] + resultArray;
        counter++;
    }

    while(llList2Integer(resultArray, 0) == 0) {
        list poly1 = llList2List(resultArray, 0, llGetListLength(resultArray) - 1);
        integer firstTerm = llList2Integer(convertToAlphaNotation(llList2List(resultArray, -1, -1)), 0);
        list poly2 = [];
        for(i = llStringLength(S_GENERATOR_POLYNOMIAL_AN_20) - 4; i >= 0; i -= 4) {
            poly2 = [((integer)llGetSubString(S_GENERATOR_POLYNOMIAL_AN_20, i, i + 2) + firstTerm) % 255] + poly2;
        }
        poly2 = convertToIntegers(poly2);
        resultArray = [];
        integer poly1Index = -1;
        for(i = llGetListLength(poly2) - 1; i >= 0; i--) {
            integer temp = llList2Integer(poly1, poly1Index) ^ llList2Integer(poly2, i);
            if(temp < 0)
                temp = (temp ^ -1) + 1;
            resultArray = [temp] + resultArray;
            poly1Index--;
        }
        integer p1Length = llGetListLength(poly1);
        while(poly1Index >= -p1Length) {
            resultArray = llList2List(poly1, poly1Index, poly1Index) + resultArray;
            poly1Index--;
        }
        while(llList2Integer(resultArray, -1) == 0) {
            resultArray = llDeleteSubList(resultArray, -1, -1);
        }
        errorProgress += progressDelta;
        errorText = "Generating codewords: " + (string) ((integer) errorProgress) + "%\n";
        updateProgress();
    }
    integer raLength = llGetListLength(resultArray);
    for(i = 0; i < raLength; i++) {
        result = decTo8BitBin(llList2Integer(resultArray, i)) + result;
    }
    return result;
}

string interleave(string _block_1, string _block_2) {
    string result = "";
    integer negativeLength = -llStringLength(_block_1);
    integer i;
    integer j;
    for(i = -1; i >= negativeLength; i -= 8) {
        result = llGetSubString(_block_2, i - 7, i) + result;
        result = llGetSubString(_block_1, i - 7, i) + result;
    }
    return result;
}

string getCodewordStream(string _message) {
    string dataStream = generateDataStream(_message);
    string dataBlock1 = llGetSubString(dataStream, 0, (integer)(llStringLength(dataStream) * 0.5) - 1);
    string dataBlock2 = llGetSubString(dataStream, (integer)(llStringLength(dataStream) * 0.5), -1);
    return interleave(dataBlock1, dataBlock2)
        + interleave(
            generateErrorCorrectionStream(dataBlock1, (integer)((NUM_DATA_CODEWORDS + NUM_EC_CODEWORDS) * 0.5)),
            generateErrorCorrectionStream(dataBlock2, (integer)((NUM_DATA_CODEWORDS + NUM_EC_CODEWORDS) * 0.5)));
}

insertDatastreamIntoQRMatrix(string finalStream) {
    // Error progress cleanup
    errorProgress = 100.0;
    errorText = "Generating codewords: 100%\n";
    updateProgress();

    integer row = 44;
    integer col = 44;
    integer index = 0;
    integer size = llStringLength(finalStream);
    integer isGoingUp = TRUE;
    integer isGoingLeft = TRUE;

    integer imageProgress = -10;
    imageText = "Creating image...\n";
    updateProgress();

    while(index < size) {

        integer subIndex = (row*45)+col;

        if(llGetSubString(qrMatrix, subIndex, subIndex) == "2") {
            // Quick masking included
            qrMatrix = llInsertString(llDeleteSubString(qrMatrix, subIndex, subIndex), subIndex, (string)((integer)llGetSubString(finalStream, index, index)^((subIndex+1)%2)));
            index++;
        }

        if(isGoingLeft) {
            col--;
            isGoingLeft = FALSE;
        }else{
            col++;
            isGoingLeft = TRUE;

            if(isGoingUp) {
                row--;
                if(row < 0) {
                    isGoingUp = FALSE;
                    row++;
                    col -= 2;
                }
            }
            else {
                row++;
                if(row > 44) {
                    isGoingUp = TRUE;
                    row--;
                    col -= 2;
                    imageProgress += 10;
                    imageText = "Creating image: " + (string) imageProgress + "%\n";
                    updateProgress();
                }
            }
        }

        if (col == 6)
            col--;
    }
    imageProgress = 100;
    imageText = "Creating image: " + (string) imageProgress + "%\n";
    updateProgress();
}

renderQRMatrix() {
    integer row;
    integer col;
    for(row = 0; row < 45; row++) {
        integer rowIndex = row*45;
        for(col = 0; col < 5; col++) {
            integer nineBitDecimal = binToDec(llGetSubString(qrMatrix, rowIndex+(col*9), rowIndex+((col*9)+8)));
            llSetLinkPrimitiveParamsFast(row+1, [
                PRIM_TEXTURE,
                (integer)llGetSubString(FACES, col, col), texture,
                <llList2Float(HORIZ_REPEATS, col), VERT_REPEAT, 0.0>,
                <llList2Float(HORIZ_OFFSETS, col)+(HORIZ_UNIT*(nineBitDecimal%TEX_COLS)), VERT_OFFSET-(VERT_UNIT*(nineBitDecimal/TEX_COLS)), 0.0>,
                0.0
                ]);
        }
    }
}

default {
    state_entry() {
        llSetText("", ZERO_VECTOR, 0.0);
        qrMatrix = "";
        texture = llGetInventoryName(INVENTORY_TEXTURE,0);
    }

    on_rez(integer start_param) {
        llResetScript();
    }
    
    link_message(integer sender, integer num, string _msg, key id) {
        llOwnerSay("Generating...");
        encodingText = "";
        errorProgress = 0.0;
        errorText = "";
        imageText = "";

        qrMatrix = "111111100222222222222222222222222200101111111100000100222222222222222222222222201001000001101110101222222222222222222222222201001011101101110100222222222222222222222222201101011101101110100222222222221111122222222211101011101100000100222222222221000122222222200001000001111111101010101010101010101010101010101111111000000001222222222221000122222222222200000000111011111222222222221111122222222222211000100222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222211111222222222221111122222222222111112222222210001222222222221000122222222222100012222222210101222222222221010122222222222101012222222210001222222222221000122222222222100012222222211111222222222221111122222222222111112222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222222222122222222222222222222222222222222222222222222022222222222222222222222222222222222222000010122222222222222222222222222222222222222011110022222222222222222222222222222222222222100110122222222222221111122222222222111112222000000001222222222221000122222222222100012222111111101222222222221010122222222222101012222100000101222222222221000122222222222100012222101110101222222222221111122222222222111112222101110100222222222222222222222222222222222222101110101222222222222222222222222222222222222100000101222222222222222222222222222222222222111111101222222222222222222222222222222222222";

        insertDatastreamIntoQRMatrix(getCodewordStream(_msg));
        llSetText("Rendering...", ZERO_VECTOR, 1.0);
        renderQRMatrix();
        llSetText("", ZERO_VECTOR, 0.0);
        llOwnerSay("Finished");
    }
}
