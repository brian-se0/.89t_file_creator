# TI-89 Titanium `.89t` File Creation Notes

## Purpose

This document records the exact process that worked in this workspace for creating a TI-89 Titanium text file (`.89t`) that:

- is accepted by TI Connect / TI Connect CE
- can contain Greek and math symbols
- is generated programmatically, not by hand-editing raw bytes

This is written so that a new ChatGPT conversation could reuse the same process without re-discovering the file format.


## Main conclusion

The reliable way to generate a sendable `.89t` file is:

1. Prepare the text as UTF-8.
2. Replace semantic Unicode symbols like `γ`, `φ`, `√`, `≥` with the specific WordRider placeholder glyphs that map to TI byte codes.
3. Use WordRider's Java class `net.wordrider.ti89.TITextFileWriter` to write the file.
4. Validate the output by checking:
   - the stored file size field equals the real file size
   - the stored checksum equals the unsigned byte sum
   - WordRider's `TITextFileReader` can open the file

Do not hand-build the container unless you absolutely have to.


## Exact local paths used in this workspace

Project root:

- `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm`

WordRider:

- `C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\wordrider.jar`
- `C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\readme.txt`
- `C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\history.txt`

Java runtime used:

- `C:\Users\FoxOS_User\Downloads\OpenJDK8U-jre_x64_windows_hotspot_8u482b08\jdk8u482-b08-jre\bin\java.exe`
- `C:\Users\FoxOS_User\Downloads\OpenJDK8U-jre_x64_windows_hotspot_8u482b08\jdk8u482-b08-jre\bin\jjs.exe`

Useful reference files created during debugging:

- Known-good user sample: `C:\Users\FoxOS_User\Documents\prob2.89t`
- Final working generated file: `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\question2.89t`
- Invalid hand-built file kept for reference: `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\question2_handbuilt_incompatible.89t`
- Intermediate UTF-8 preview text: `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\.tmp_question2_preview.txt`
- Original markdown source: `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\ECON504_Pr2Type.md`
- Probe files for symbol mapping:
  - `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\wr_symbols.89t`
  - `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\wr_greekmap.89t`
  - `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\wr_math1map.89t`
  - `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\wr_math2map.89t`


## External links

Official TI links:

- TI-89 Titanium guidebook page:
  - https://education.ti.com/en-ph/guidebook/details/en/FA1DC891957E4700B46A67255850C592/89ti
- TI knowledge base: file extensions for graphing calculators:
  - https://education.ti.com/en/customer-support/knowledge-base/ti-83-84-plus-family/product-usage/29430
- TI knowledge base: TI-89 Titanium compatibility with TI-89 files:
  - https://education.ti.com/en/customer-support/knowledge-base/other-graphing/general-information/12078

Historical WordRider links referenced by the bundled docs:

- http://wordrider.net
- http://wordrider.net/forum


## What the local WordRider docs say

Important lines from `readme.txt`:

- `readme.txt:103-107` explains that WordRider is written in Java, cannot use the original bitmap font, and therefore uses the `TI92PlusPC (ti-92p.ttf)` TrueType font.
- `readme.txt:107` says the font does not fully support all TI-89 characters.
- `readme.txt:81-83` says that if some characters are not displayed, you should use an alternate character.

Important lines from `history.txt`:

- `history.txt:55-56` says WordRider shows shortcuts for characters with code `<255`, for example `alt-0128 for alfa char`.
- `history.txt:62` says an older checksum bug for long `.89t` files was fixed.
- `history.txt:22` says spaces at the beginning of lines were a compatibility issue and were fixed.
- `history.txt:20` mentions `Alt+/` for sqrt.

Why this matters:

- The WordRider UI is not using semantic Unicode Greek/math in the way a normal modern text editor would.
- It is using placeholder characters that are later converted to TI byte codes.
- Therefore, if you feed true Unicode directly to the writer, you may get the wrong bytes even if the file is structurally valid.


## What failed and why

The first hand-built file, `question2_handbuilt_incompatible.89t`, failed in TI Connect because it had multiple format problems:

- Real file length: `23862`
- Stored size field: `23860`
- Stored body length: `0x5CDC`
- Correct working body length for the fixed version: `0x5CDD`
- The content body also started with an extra leading space byte:
  - invalid file started with `20 45 43 4F 4E 20`
  - valid file starts with `45 43 4F 4E 20 35`

Meaning:

- the total file-size field was wrong
- the body-length field was wrong
- I had incorrectly inserted a leading space before each line
- I had also used the wrong symbol-to-byte assumptions for some characters


## Preferred workflow

### Step 1: prepare a UTF-8 text file

Start from a plain UTF-8 text file. In this workspace, the exact file used was:

- `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\.tmp_question2_preview.txt`

This was the content that should appear on the calculator, before converting symbols to WordRider placeholders.


### Step 2: replace semantic Unicode with WordRider placeholders

This is the most important rule.

Do not feed `γ`, `φ`, `√`, `∞`, `≥`, `≠`, etc. directly into `TITextFileWriter`.

Instead, replace them with the placeholder characters that WordRider understands.

For some mappings, the replacement is a visible CP1252-style glyph such as `ƒ` or `ž`.
For others, the replacement is a control character and should be written in code as `\u008D`, `\u008F`, or `\u009D`.


## Verified Greek mapping

These mappings were verified by generating `wr_greekmap.89t` from the actual `Greek chars` table in WordRider and reading the emitted bytes.

Format:

- Intended symbol = what you want logically
- JS replacement literal = what you should put into the string before calling `TITextFileWriter`
- Emitted TI byte = byte that actually appears in the `.89t` content

| Intended symbol | JS replacement literal | Replacement code point | Emitted TI byte |
| --- | --- | --- | --- |
| `α` | `\u20AC` (`€`) | `U+20AC` | `0x80` |
| `β` | `\u0081` | `U+0081` | `0x81` |
| `Γ` | `\u201A` (`‚`) | `U+201A` | `0x82` |
| `γ` | `\u0192` (`ƒ`) | `U+0192` | `0x83` |
| `Δ` | `\u201E` (`„`) | `U+201E` | `0x84` |
| `δ` | `\u2026` (`…`) | `U+2026` | `0x85` |
| `ε` | `\u2020` (`†`) | `U+2020` | `0x86` |
| `ζ` | `\u2021` (`‡`) | `U+2021` | `0x87` |
| `θ` | `\u02C6` (`ˆ`) | `U+02C6` | `0x88` |
| `λ` | `\u2030` (`‰`) | `U+2030` | `0x89` |
| `μ` | `\u00B1` (`±`) | `U+00B1` | `0xB5` |
| `ξ` | `\u0160` (`Š`) | `U+0160` | `0x8A` |
| `π` | `\u0152` (`Œ`) | `U+0152` | `0x8C` |
| `ρ` | `\u008D` | `U+008D` | `0x8D` |
| `σ` | `\u008F` | `U+008F` | `0x8F` |
| `τ` | `\u0090` | `U+0090` | `0x90` |
| `φ` | `\u2018` (`‘`) | `U+2018` | `0x91` |
| `ψ` | `\u2019` (`’`) | `U+2019` | `0x92` |
| `Ω` | `\u201C` (`“`) | `U+201C` | `0x93` |
| `ω` | `\u201D` (`”`) | `U+201D` | `0x94` |
| integral sign from WordRider Greek table | `\u00B7` (`·`) | `U+00B7` | `0xBD` |
| `d` entry from WordRider Greek table | `\u00B6` (`¶`) | `U+00B6` | `0xBC` |
| `Σ` | `\u017D` (`Ž`) | `U+017D` | `0x8E` |
| `Π` | `\u2039` (`‹`) | `U+2039` | `0x8B` |

Notes:

- The odd mappings such as `μ -> ± -> 0xB5` are not typos. They are the actual WordRider/TI font pipeline mappings observed in this workspace.
- For the control-char entries, do not try to type them directly in a normal editor. Use `\u008D`, `\u008F`, etc. in JavaScript.


## Verified common math mapping

These were verified either from `wr_symbols.89t` or from the emitted bytes of `wr_math1map.89t`.

| Intended symbol | JS replacement literal | Replacement code point | Emitted TI byte |
| --- | --- | --- | --- |
| `√` | `\u00A7` (`§`) | `U+00A7` | `0xA8` |
| `∞` | `\u00B8` (`¸`) | `U+00B8` | `0xBE` |
| `≤` | `\u0153` (`œ`) | `U+0153` | `0x9C` |
| `≥` | `\u017E` (`ž`) | `U+017E` | `0x9E` |
| `≠` | `\u009D` | `U+009D` | `0x9D` |
| degree sign from WordRider Math #1 | `\u00B0` (`°`) | `U+00B0` | `0xB0` |
| `π` from WordRider Math #1 | `\u0152` (`Œ`) | `U+0152` | `0x8C` |

If you need more math symbols than the table above, use the discovery method described later in this document.


## Exact script that generated the working file

This is the exact JavaScript/Nashorn file used to produce the fixed output.

```javascript
var Files = Java.type('java.nio.file.Files');
var Paths = Java.type('java.nio.file.Paths');
var StandardCharsets = Java.type('java.nio.charset.StandardCharsets');
var File = Java.type('java.io.File');
var TITextFileWriter = Java.type('net.wordrider.ti89.TITextFileWriter');
var TIFileInfo = Java.type('net.wordrider.ti89.TIFileInfo');

var p = Paths.get('c:/Users/FoxOS_User/Downloads/Forecasting_Midterm-20260310T062838Z-1-001/Forecasting_Midterm/.tmp_question2_preview.txt');
var text = new java.lang.String(Files.readAllBytes(p), StandardCharsets.UTF_8);

var map = {
  '\u03B3':'\u0192',
  '\u03B5':'\u2020',
  '\u03B8':'\u02C6',
  '\u03BC':'\u00B1',
  '\u03C1':'\u008D',
  '\u03C3':'\u008F',
  '\u03C6':'\u2018',
  '\u221A':'\u00A7',
  '\u221E':'\u00B8',
  '\u2260':'\u009D',
  '\u2265':'\u017E'
};

for (var k in map) {
  text = text.split(k).join(map[k]);
}

var w = new TITextFileWriter();
var info = new TIFileInfo();

info.setFolderName('main');
info.setComment('generated by WordRider');
info.setVarName('questio2');
info.setStoreType(0, false);

w.setFileInfo(info);
w.setTextContent(text);

var ok = w.saveToFile(
  new File('c:/Users/FoxOS_User/Downloads/Forecasting_Midterm-20260310T062838Z-1-001/Forecasting_Midterm/question2_fixed.89t')
);

print('saved=' + ok + ' textLen=' + text.length());
```


## Exact command to run the script

```powershell
& 'C:\Users\FoxOS_User\Downloads\OpenJDK8U-jre_x64_windows_hotspot_8u482b08\jdk8u482-b08-jre\bin\jjs.exe' `
  -cp 'C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\wordrider.jar' `
  -scripting .tmp_wr_write_fixed.js
```

Notes:

- This uses Nashorn (`jjs.exe`) from Java 8.
- `wordrider.jar` is added to the classpath.
- The output file path can be changed.
- Keep the TI variable name short. In practice, an 8-character `varName` is the safe choice. The working file used `questio2`.


## Exact command to open WordRider GUI

This is the exact command already used on this machine:

```powershell
"C:\Users\FoxOS_User\Downloads\OpenJDK8U-jre_x64_windows_hotspot_8u482b08\jdk8u482-b08-jre\bin\java.exe" -jar "C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\wordrider.jar"
```

Use this if you want to inspect the character menus manually.


## Validation commands

### 1. Structural byte check

This PowerShell snippet checks the exact fields that mattered for `question2.89t`:

```powershell
$b=[IO.File]::ReadAllBytes((Resolve-Path 'question2.89t'))
[pscustomobject]@{
  Length    = $b.Length
  SizeField = [BitConverter]::ToUInt32($b,76)
  StoredLE  = ('{0:X4}' -f [BitConverter]::ToUInt16($b,$b.Length-2))
  Sum82     = ('{0:X4}' -f (($b[82..($b.Length-3)] | Measure-Object -Sum).Sum -band 0xFFFF))
  BodyLenBE = ('{0:X2}{1:X2}' -f $b[86],$b[87])
  Var       = [Text.Encoding]::ASCII.GetString($b[64..71]).Trim([char]0)
} | Format-List
```

For the final working `question2.89t`, the result was:

- `Length    = 23863`
- `SizeField = 23863`
- `StoredLE  = 92A7`
- `Sum82     = 92A7`
- `BodyLenBE = 5CDD`
- `Var       = questio2`

Interpretation:

- `Length` must equal `SizeField`
- `StoredLE` must equal `Sum82`


### 2. Reader round-trip check

This verifies that WordRider's TI reader can open the final file:

```javascript
var File = Java.type('java.io.File');
var R = Java.type('net.wordrider.ti89.TITextFileReader');
var r = new R();
var ok = r.openFromFile(new File('c:/Users/FoxOS_User/Downloads/Forecasting_Midterm-20260310T062838Z-1-001/Forecasting_Midterm/question2.89t'));
print('open=' + ok + ' len=' + String(r.getContent()).length());
```

Run it with:

```powershell
& 'C:\Users\FoxOS_User\Downloads\OpenJDK8U-jre_x64_windows_hotspot_8u482b08\jdk8u482-b08-jre\bin\jjs.exe' `
  -cp 'C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\wordrider.jar' `
  -scripting .tmp_wr_final_check.js
```

For the final working file, the result was:

- `open=true len=23769`


## Manual format notes

Again, the preferred method is to let `TITextFileWriter` build the container.

If you ever must inspect the bytes manually, these fields were observed in valid files:

- Offset `0..7`: ASCII header `**TI92P*`
- Offset `10..17`: folder name padded to 8 bytes, usually `main`
- Offset `18..57`: comment padded to 40 bytes
- Offset `64..71`: variable name padded to 8 bytes
- Offset `72..75`: `0B 00 FF 00`
- Offset `76..79`: little-endian total file length, including checksum bytes
- Offset `80..81`: `A5 5A`
- Offset `82..85`: `00 00 00 00`
- Offset `86..87`: big-endian body length
- Offset `88..89`: `00 01`
- Offset `90..`: text content bytes, separated by `0D`
- End of content marker: `00 E0`
- Final two bytes: little-endian checksum

Observed checksum rule from valid files:

- checksum = unsigned sum of bytes from offset `82` through the byte before the checksum

Observed body-length rule from valid files:

- body length = number of bytes from offset `88` through the byte before the checksum

The invalid hand-built file failed because these fields did not agree with the real byte layout.


## How to discover additional symbol mappings

If you need more symbols than the verified tables above, do not guess.

Use WordRider's own character tables and writer to probe them.

### Discovery idea

1. Read the character array out of `CharacterList$CharsTableModel`.
2. Write one character per line through `TITextFileWriter`.
3. Inspect the raw bytes after offset `90`.
4. Match the emitted bytes back to the menu order.

This is how the verified tables in this document were produced.


### Example discovery script for the Greek table

```javascript
var File = Java.type('java.io.File');
var TITextFileWriter = Java.type('net.wordrider.ti89.TITextFileWriter');
var TIFileInfo = Java.type('net.wordrider.ti89.TIFileInfo');
var CL = Java.type('net.wordrider.plugintools.CharacterList$CharsTableModel').class;

var f = CL.getDeclaredField('GREEK_CHARS');
f.setAccessible(true);
var arr = f.get(null);

var lines = [];
for (var i = 0; i < java.lang.reflect.Array.getLength(arr); i++) {
  lines.push('' + java.lang.reflect.Array.getChar(arr, i));
}

var w = new TITextFileWriter();
var info = new TIFileInfo();
info.setFolderName('main');
info.setComment('generated by WordRider');
info.setVarName('grkmap');
info.setStoreType(0, false);

w.setFileInfo(info);
w.setTextContent(lines.join('\n'));
w.saveToFile(new File('c:/Users/FoxOS_User/Downloads/Forecasting_Midterm-20260310T062838Z-1-001/Forecasting_Midterm/wr_greekmap.89t'));
```

Then inspect it:

```powershell
$b=[IO.File]::ReadAllBytes((Resolve-Path 'wr_greekmap.89t'))
($b[90..($b.Length-3)] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
```

The emitted byte sequence obtained in this workspace was:

```text
80 0D 81 0D 82 0D 83 0D 84 0D 85 0D 86 0D 87 0D 88 0D 89 0D B5 0D 8A 0D 8C 0D 8D 0D 8F 0D 90 0D 91 0D 92 0D 93 0D 94 0D BD 0D BC 0D 8E 0D 8B 00 E0
```

The important part is the non-`0D` bytes. Those are the TI bytes emitted for the Greek menu entries in order.

Note:

- The exact captured file in this workspace is `wr_greekmap.89t`.
- Similar probe files were also created for `Math symbols #1` and `Math symbols #2`.


## Practical checklist for a new ChatGPT session

If a future ChatGPT session needs to generate a sendable `.89t` file on this machine, it should do the following:

1. Read this document first.
2. Use the exact Java and WordRider paths listed above.
3. Start from UTF-8 source text.
4. Replace semantic Greek/math Unicode with the verified WordRider placeholders.
5. Write the file with `TITextFileWriter`, not by hand.
6. Keep the TI variable name short, for example `questio2`.
7. Run the structural validation snippet.
8. Run the reader round-trip snippet.
9. If a new symbol is needed, generate a probe file instead of guessing the byte code.


## Final verified result in this workspace

The file that successfully sent to the calculator after debugging was:

- `C:\Users\FoxOS_User\Downloads\Forecasting_Midterm-20260310T062838Z-1-001\Forecasting_Midterm\question2.89t`

It was produced by:

- starting from `.tmp_question2_preview.txt`
- converting semantic symbols to WordRider placeholders
- writing with `TITextFileWriter`
- verifying checksum and size

That is the process to repeat.
