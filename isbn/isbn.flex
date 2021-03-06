import java.util.regex.Matcher;
import java.util.regex.Pattern;

class ISBNMapper {
    private int language; // language code
    private int publisher; // publisher code
    private int checksum; // original checksum code, x will be converted to 10

    private boolean isValid; // if this ISBN is valid
    private int type; // 10 or 13
    private int[] digits; // digits in the original string
    private String[] groups; // group of numbers in the original string
                          // x will be converted to 10
    private final static int GROUP_NUM = 4;
    private final static int ISBN13_LEN = 13 + 4;
    private final static int ISBN10_LEN = 10 + 3;
    public final static int ISBN10_TYPE = 10;
    public final static int ISBN13_TYPE = 13;

    /**
     * Constructor, receive an ISBN String, validate it, and parse the
     * information if the string is valid.
     *
     * @see http://en.wikipedia.org/wiki/International_Standard_Book_Number
     *
     * @param raw
     *            the ISBN string to parse
     */
    public ISBNMapper(String raw) {
        Pattern pattern = Pattern
                .compile("(?:97[89][- ])?(\\d+[- ])(\\d+[- ])(\\d+[- ])([xX\\d])");
        Matcher matcher = pattern.matcher(raw);

        // the string match the format
        if (matcher.find()) {
            int rawlen = raw.length(); // cache the original length

            // eliminate strings with wrong length
            if (rawlen != ISBN13_LEN && rawlen != ISBN10_LEN) {
                isValid = false;
                return;
            }

            // string containing the first 12 or 9 digits
            String numString = raw.substring(0, rawlen - 1).replace(" ", "")
                    .replace("-", "");
            type = (rawlen == ISBN13_LEN) ? ISBN13_TYPE : ISBN10_TYPE;

            char checksumChar = raw.charAt(rawlen - 1);
            if (checksumChar == 'x' || checksumChar == 'X') {
                checksum = 10;
            } else {
                checksum = Character.getNumericValue(checksumChar);
            }

            // convert digit characters to integers
            digits = new int[type - 1];
            for (int i = 0; i < type - 1; ++i)
                digits[i] = Character.getNumericValue(numString.charAt(i));

            // checksum error
            if (!this.hasValidChecksum()) {
                isValid = false;
                return;
            }

            groups = new String[GROUP_NUM];
            for (int i = 0; i < GROUP_NUM - 1; ++i)
                groups[i] = matcher.group(i + 1)
                        .replace(" ", "").replace("-", "");
            groups[3] = raw.substring(raw.length() - 1);

            language = Integer.parseInt(groups[0]);
            publisher = Integer.parseInt(groups[1]);
            isValid = true;
        } else {
            isValid = false;
        }
    }

    public String getCountry() {
        if (!isValid) return null;

        switch (language) {
        case 0: return "English";
        case 7: return "Chinese";
        default: return "Other";
        }
    }

    public String getPublisher() {
        if (!isValid) return null;
        return groups[1];
    }

    public boolean isValid() {
        return isValid;
    }

    /**
     * Check if this ISBN has valid checksum.
     *
     * Needs this.digits[] and this.checksum in place.
     */
    private boolean hasValidChecksum() {
        int sum = 0;
        if (type == 10) {
            for (int i = 0, j = 10; i < type - 1; ++i, --j)
                sum += digits[i] * j;
            return checksum == (11 - (sum % 11)) % 11;
        } else {
            for (int i = 0; i < type - 1; ++i)
                sum += digits[i] * (i % 2 == 0 ? 1 : 3);
            return checksum == (10 - (sum % 10)) % 10;
        }
    }
}

%%

%public
%class ISBN
%standalone
%int

DIGIT=[0-9]
ISBN=(97[89][\- ])?({DIGIT}+[\- ]){3}(x|X|{DIGIT})
ANYTHING=[^\r\n]+

%%
^{ISBN}$ {
    ISBNMapper mapper = new ISBNMapper(yytext().replace("\n", ""));
    if (mapper.isValid()) {
        System.out.println(mapper.getCountry() + " " + mapper.getPublisher());
    } else {
        System.out.println("Error");
    }
}

{ANYTHING}$ { System.out.println("Error"); }
^{ANYTHING}$ { System.out.println("Error"); }
\n\n { System.out.println(""); }
. { /* skip */ }
\n { /* skip */ }
