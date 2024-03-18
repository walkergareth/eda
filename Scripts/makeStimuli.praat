# makeStimuli.praat. Praat script to create a new set of files from
# the English Dialects App corpus to be used as stimuli. Audio files
# have beeps at the start.  TextGrid files have a new tier where
# intervals correspond to chunks of the story.

# Copyright (C) 2024 Gareth Walker.

# g.walker@sheffield.ac.uk
# School of English
# University of Sheffield
# Jessop West
# 1 Upper Hanover Street
# Sheffield
# S3 7RA

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

# where files are stored, relative to this script
fileDir$ = "../Concatenated/"

# where to save files, relative to this script
saveDir$ = "../Experiment/"

# create folder to store concatenated versions
createFolder: saveDir$
createFolder: saveDir$ + "textgrids"
createFolder: saveDir$ + "wav"

# code to make beeps which can then be added to WAV files

# number of beeps
beeps = 4
# carrier frequency of beeps
freq = 500

# make the beeps
for i from 1 to beeps-1
  beep [i] = Create Sound from formula: "beep", 1, 0, 1, 44100, "0.3 * sin (2*pi*freq*x)*exp(-0.5*(x/0.01)^2)"
endfor
longbeep = Create Sound from formula: "longbeep", 1, 0, 1, 44100, "0.3 * sin (2*pi*freq*x)*exp(-0.5*(x/0.1)^2)"

# select the beeps
for i from 1 to beeps-1
  plusObject: beep [i]
endfor

# concatenate the beeps
beepFile = Concatenate
Scale peak: 0.99

# clean up
selectObject ()
for i from 1 to beeps-1
  plusObject: beep [i]
endfor
plusObject: longbeep
Remove

########################
# read in the files

strings = Create Strings as file list: "list", fileDir$ + "wav/*.wav"
numberOfFiles = Get number of strings
for ifile to numberOfFiles
  selectObject: strings
  fileName$ = Get string: ifile
  spkr$ = Get string: ifile
  spkr$ = replace$ (spkr$, ".wav", "", 0)
  # read in the WAV file and add beeps
  sound = Read from file: fileDir$ + "wav/" + spkr$ + ".wav"
  selectObject: beepFile
  plusObject: sound
  chain = Concatenate
  Save as WAV file: saveDir$ + "wav/" + spkr$ + ".wav"

  # work on the TextGrid files
  # add time for beeps
  tg = Read from file: fileDir$ + "textgrids/" + spkr$ + ".TextGrid"
  Extend time: beeps, "start"
  Shift times to: "start time", 0

  # tier containing words
  words = 2
  intsTotal = Get number of intervals: words

  # add a tier
  tiers = Get number of tiers
  Insert interval tier: tiers+1, "chunks"

  firstInt = 1

  procedure getChunk
    # get first 'real' interval
    repeat
      firstLab$ = Get label of interval: words, firstInt
      firstInt = firstInt + 1
    until firstLab$ <> "" and firstLab$ <> "SENT-END" 
    int = firstInt - 1
    # get final interval
    start = Get start time of interval: words, int
    label$ = ""
    repeat
      lab$ = Get label of interval: words, int
      int = int + 1
      label$ = label$ + lab$ + " "
    until lab$ = target$
    # a hack for "WOLF WOLF"
    if target$ = "WOLF"
      int = int + 1
      label$ = label$ + target$
    endif
    # make lower case
    label$ = replace_regex$ (label$, "('label$')", "\L\1", 1)
    # remove final space
    label$ = replace_regex$ (label$, " $", "", 1)
    # remove any duplicated spaces
    label$ = replace_regex$ (label$, "  ", " ", 1)
    end = Get start time of interval: words, int

    # add starting boundary
    newInts = Get number of intervals: tiers+1
    startTime = Get start time of interval: tiers+1, newInts
    if startTime <> start
      Insert boundary: tiers+1, start
    endif

    # add ending boundary
    newInts = Get number of intervals: tiers+1
    endTime = Get start time of interval: tiers+1, newInts
    if endTime <> end
      Insert boundary: tiers+1, end
    endif

    # add label
    Set interval text: tiers+1, newInts, label$

    # reset
    label$ = ""
    firstInt = int
  endproc

  # go through the chunks
  target$ = "BOY"
  @getChunk
  target$ = "FIELDS"
  @getChunk
  target$ = "MOUNTAIN"
  @getChunk
  target$ = "PLAN"
  @getChunk
  target$ = "FUN"
  @getChunk
  target$ = "AIR"
  @getChunk
  target$ = "WOLF"
  @getChunk
  target$ = "HIM"
  @getChunk
  target$ = "HOMES"
  @getChunk
  target$ = "SAFETY"
  @getChunk
  target$ = "WHILE"
  @getChunk
  target$ = "PLEASURE"
  @getChunk
  target$ = "AGAIN"
  @getChunk
  target$ = "SUCCESSFUL"
  @getChunk
  target$ = "AFTER"
  @getChunk
  target$ = "ZOO"
  @getChunk
  target$ = "DUCK"
  @getChunk
  target$ = "SHOT"
  @getChunk
  target$ = "FOREST"
  @getChunk
  target$ = "SHEEP"
  @getChunk
  target$ = "VILLAGE"
  @getChunk
  target$ = "BEFORE"
  @getChunk
  target$ = "VILLAGERS"
  @getChunk
  target$ = "TIME"
  @getChunk
  target$ = "AGAIN"
  @getChunk
  target$ = "FEAST"
  @getChunk

  Save as text file: saveDir$ + "textgrids/" + spkr$ + ".TextGrid"

  # clean up
  selectObject: sound, chain, tg
  Remove

endfor

# clean up
selectObject: strings, beepFile
Remove

