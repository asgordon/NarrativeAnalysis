# NarrativeAnalysis

This program analyzes subjectivity and narrative levels
(diegetic levels) in personal stories (first person
narratives).

Three languages are supported: English, Farsi and Chinese.
The software for each language is found in directories
named en, fa and cn, respectively.


## Installing

Model files are compressed using gzip, and need to be 
unzipped before using. From a linux command line prompt, 
type:

    make


## Using

The input to the program is a personal story in plain
text format. 

    perl NarrativeAnalysis.pl story.txt


The program performs the analysis in three
steps, described below.

### 1. Segmentation

The text is segmented into discourse units, where each
unit is a span of text that has a single subjectivity
label and a single narrative level.

### 2. Narrative Level classification

Each segmented is classified as Diegetic or Extradiegetic.

Diegetic segments (shown in the output as D) are those
segments of the story that correspond to the level of the
story where the author is a character.

Extradiegetic segments (shown in the output as E) are
those segments of the story that correspond to the level
of the story where the author is the narrator or
storyteller.

### 3. Subjectivity classification

Each segment is classified as Subjective (S) or
Objective (O).

Subjective segments are those that correspond to mental
processes, opinions, beliefs, etc.

Objective segments are those that describe observable
events or states in the world.

## About

For more information, please see:

* Sagae, K., Gordon, A., Dehghani, M., Metke, M., Kim, J., Gimbel, S., Tipper, C., Kaplan, J., and Immordino-Yang, M. (2013) A Data-Driven Approach for Classification of Subjectivity in Personal Narrative. 2013 Workshop on Computational Models of Narrative, August 4-6, 2013, Hamburg, Germany. 
http://people.ict.usc.edu/~gordon/publications/CMN13.PDF

If you publish work that uses this software, please cite
the paper above.

* v0.2: Minor changes to tokenization in English (KS Sep 9 2014)
* v0.1: Initial release

Licence
-------

Copyright (c) 2014, University of Southern California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



