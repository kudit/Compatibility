// MARK: - Legacy Unicode emoji properties
// Derived from https://www.unicode.org/Public/emoji/3.0/emoji-data.txt (2016-06-02).
// The source data is Copyright © 2016 Unicode, Inc.; the license notice follows below.

/// A fixed Emoji 3.0 property table for systems without Unicode.Scalar.Properties.isEmoji.
///
/// This preserves real emoji-property boundaries instead of treating entire symbol blocks as
/// emoji. Newer systems continue to use their native Unicode database; characters introduced
/// after Emoji 3.0 are intentionally not recognized by this legacy fallback.
internal enum LegacyEmoji {
    /// Whether the scalar had the Emoji property in Unicode's published Emoji 3.0 data.
    static func contains(_ scalar: Unicode.Scalar) -> Bool {
        // Immutable ranges can be read on any executor and need no synchronization or OS API.
        return ranges.contains { $0.contains(scalar.value) }
    }

    // Generated from rows whose property is exactly Emoji; adjacent intervals are merged.
    // Missing code points remain false, including non-emoji symbols between these intervals.
    private static let ranges: [ClosedRange<UInt32>] = [
        0x23...0x23, 0x2A...0x2A, 0x30...0x39, 0xA9...0xA9,
        0xAE...0xAE, 0x203C...0x203C, 0x2049...0x2049, 0x2122...0x2122,
        0x2139...0x2139, 0x2194...0x2199, 0x21A9...0x21AA, 0x231A...0x231B,
        0x2328...0x2328, 0x23CF...0x23CF, 0x23E9...0x23F3, 0x23F8...0x23FA,
        0x24C2...0x24C2, 0x25AA...0x25AB, 0x25B6...0x25B6, 0x25C0...0x25C0,
        0x25FB...0x25FE, 0x2600...0x2604, 0x260E...0x260E, 0x2611...0x2611,
        0x2614...0x2615, 0x2618...0x2618, 0x261D...0x261D, 0x2620...0x2620,
        0x2622...0x2623, 0x2626...0x2626, 0x262A...0x262A, 0x262E...0x262F,
        0x2638...0x263A, 0x2648...0x2653, 0x2660...0x2660, 0x2663...0x2663,
        0x2665...0x2666, 0x2668...0x2668, 0x267B...0x267B, 0x267F...0x267F,
        0x2692...0x2694, 0x2696...0x2697, 0x2699...0x2699, 0x269B...0x269C,
        0x26A0...0x26A1, 0x26AA...0x26AB, 0x26B0...0x26B1, 0x26BD...0x26BE,
        0x26C4...0x26C5, 0x26C8...0x26C8, 0x26CE...0x26CF, 0x26D1...0x26D1,
        0x26D3...0x26D4, 0x26E9...0x26EA, 0x26F0...0x26F5, 0x26F7...0x26FA,
        0x26FD...0x26FD, 0x2702...0x2702, 0x2705...0x2705, 0x2708...0x270D,
        0x270F...0x270F, 0x2712...0x2712, 0x2714...0x2714, 0x2716...0x2716,
        0x271D...0x271D, 0x2721...0x2721, 0x2728...0x2728, 0x2733...0x2734,
        0x2744...0x2744, 0x2747...0x2747, 0x274C...0x274C, 0x274E...0x274E,
        0x2753...0x2755, 0x2757...0x2757, 0x2763...0x2764, 0x2795...0x2797,
        0x27A1...0x27A1, 0x27B0...0x27B0, 0x27BF...0x27BF, 0x2934...0x2935,
        0x2B05...0x2B07, 0x2B1B...0x2B1C, 0x2B50...0x2B50, 0x2B55...0x2B55,
        0x3030...0x3030, 0x303D...0x303D, 0x3297...0x3297, 0x3299...0x3299,
        0x1F004...0x1F004, 0x1F0CF...0x1F0CF, 0x1F170...0x1F171, 0x1F17E...0x1F17F,
        0x1F18E...0x1F18E, 0x1F191...0x1F19A, 0x1F1E6...0x1F1FF, 0x1F201...0x1F202,
        0x1F21A...0x1F21A, 0x1F22F...0x1F22F, 0x1F232...0x1F23A, 0x1F250...0x1F251,
        0x1F300...0x1F321, 0x1F324...0x1F393, 0x1F396...0x1F397, 0x1F399...0x1F39B,
        0x1F39E...0x1F3F0, 0x1F3F3...0x1F3F5, 0x1F3F7...0x1F4FD, 0x1F4FF...0x1F53D,
        0x1F549...0x1F54E, 0x1F550...0x1F567, 0x1F56F...0x1F570, 0x1F573...0x1F57A,
        0x1F587...0x1F587, 0x1F58A...0x1F58D, 0x1F590...0x1F590, 0x1F595...0x1F596,
        0x1F5A4...0x1F5A5, 0x1F5A8...0x1F5A8, 0x1F5B1...0x1F5B2, 0x1F5BC...0x1F5BC,
        0x1F5C2...0x1F5C4, 0x1F5D1...0x1F5D3, 0x1F5DC...0x1F5DE, 0x1F5E1...0x1F5E1,
        0x1F5E3...0x1F5E3, 0x1F5E8...0x1F5E8, 0x1F5EF...0x1F5EF, 0x1F5F3...0x1F5F3,
        0x1F5FA...0x1F64F, 0x1F680...0x1F6C5, 0x1F6CB...0x1F6D2, 0x1F6E0...0x1F6E5,
        0x1F6E9...0x1F6E9, 0x1F6EB...0x1F6EC, 0x1F6F0...0x1F6F0, 0x1F6F3...0x1F6F6,
        0x1F910...0x1F91E, 0x1F920...0x1F927, 0x1F930...0x1F930, 0x1F933...0x1F93A,
        0x1F93C...0x1F93E, 0x1F940...0x1F945, 0x1F947...0x1F94B, 0x1F950...0x1F95E,
        0x1F980...0x1F991, 0x1F9C0...0x1F9C0,
    ]
}

/*
UNICODE LICENSE V3

COPYRIGHT AND PERMISSION NOTICE

Copyright © 1991-2026 Unicode, Inc.

NOTICE TO USER: Carefully read the following legal agreement. BY
DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING DATA FILES, AND/OR
SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT
DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE THE DATA FILES OR SOFTWARE.

Permission is hereby granted, free of charge, to any person obtaining a
copy of data files and any associated documentation (the "Data Files") or
software and any associated documentation (the "Software") to deal in the
Data Files or Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, and/or sell
copies of the Data Files or Software, and to permit persons to whom the
Data Files or Software are furnished to do so, provided that either (a)
this copyright and permission notice appear with all copies of the Data
Files or Software, or (b) this copyright and permission notice appear in
associated Documentation.

THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
THIRD PARTY RIGHTS.

IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE
BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THE DATA
FILES OR SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall
not be used in advertising or otherwise to promote the sale, use or other
dealings in these Data Files or Software without prior written
authorization of the copyright holder.
*/
