# OTG Command

Addon for Wildstar for Commanding Guild and Raids.

Initially focused on OTG DKP tracking and deduplication of Player Toon Roster.

## Installation

Download zip version.
Extract it to addons directory.

## Usage

- /otg brings up addon
- /otgreset resets addon saved data on next reload

Addon needs data from the guildroster, the wildstar game typically polls this about once every few minutes.  You can force it immediately by visiting the guild roster in the ingame social tab (o).

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History

### 0.3 beta

- Added Version # to main Window bottom right
- Added and Centered Player Name Plate to make Spotting Player Name easier
- Moved Player Rank from Name to Below Stats right justified
- Moved Toon Level to its own Icon type of display like class and path
- Moved what will be a Filter Feature for Raids back to left.

### 0.2 beta

- Fixed upper right close button

### 0.1 beta

- Tighten Up the interface list to remove extra space.
- Made DKP Editable
- Added Auto Save Functionality To Store Roster and DKP
- Added Support to merge new guildies
- Added a /otgreset command so that data can be cleared during testing
- The Raid filter is still not functional

### 0.1 Alpha(s)

- Fixed Crispins complaint on scroll wheeling
- Moved Rank to after player name
- Positioned Label where the DKP is going to show and be editable
- Modified The Toons List 
- Used Icons and Tool Tip for Class instead of word
- Used Icons and Tool Tip for Path instead of word
- Presented Toon Level in brackets after Toon Name
- Changed Ok Button to Save But it still isn't hooked to anything yet
- Added Filter Toggle for Filtering by Whoes in Raid Currently - Not hooked to anything yet
- Attachments area

## Credits

- Diatana
- Via
- Sarine
- Crispin

## License

MIT License

Copyright (c) 2016 Richard Ashwell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.