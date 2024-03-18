# combineEDA.praat. Praat script to combine recorded passages from the 
# English Dialects App corpus.

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

# padding (in seconds) at the start and end of each sentence
pad = 0.2

# where files are stored, relative to this script
fileDir$ = "../Renamed/"

# where to save files, relative to this script
saveDir$ = "../Concatenated/"

# create folder to store concatenated versions
createFolder: saveDir$
createFolder: saveDir$ + "textgrids"
createFolder: saveDir$ + "wav"

# get a list of all the speakers, from the folders
spkrs = Create Strings as folder list: "spkrs", fileDir$ + "*"
numberOfSpkrs = Get number of strings

for s to numberOfSpkrs
  selectObject: spkrs
  spkrName$ = Get string: s

  # loop through the files for the speaker
  strings = Create Strings as file list: "files", fileDir$ + spkrName$ + "/wav/" + "*.wav"
  numberOfFiles = Get number of strings
  for i to numberOfFiles
    selectObject: strings
    file$ = Get string: i
    file$ = replace$ (file$, ".wav", "", 0)
      
    # read in the sound file
    sound [i] = Read from file: fileDir$ + spkrName$ + "/wav/" + file$ + ".wav"
    dur = Get total duration
    # create a TextGrid looking for when noise starts and ends
    textGridSil [i] = noprogress To TextGrid (voice activity): 
      ...0, 0.3, 0.1, 70, 6000, -10, -35, 0.1, 0.1, "silent", "sounding"

    # the number of the tier in the created TextGrid to examine
    tier = 1
    # get the number of intervals on the specified tier
    ints = Get number of intervals: tier
    # get the label of the first interval on the specified tier 
    lab$ = Get label of interval: tier, 1
    # if the interval is labelled 'silence' use the end of that interval as the start time
    if lab$ = "silence"
      beg = Get end time of interval: tier, 1
    # ...otherwise, start from 0
    else
      beg = 0
    endif

    # get the label of the first interval on the specified tier 
    lab$ = Get label of interval: tier, ints
    # if the interval is labelled 'silence' use the start of that interval as the start time
    if lab$ = "silence"
      end = Get end time of interval: tier, ints
    # ...otherwise, end at the end of the sound
    else
      end = dur
    endif
    # if there isn't room for padding at the start
    if beg-pad > 0
      beg = beg-pad
    else
      beg = 0
    endif
    # if there isn't room for padding at the end
    if end+pad <= dur
      end = end+pad
    else
      end = dur
    endif

    # get the bit of the Sound
    selectObject: sound [i]
    # get nearest zero crossings to beg and end (start and end of noise)
    begZ = Get nearest zero crossing: 1, beg
    endZ = Get nearest zero crossing: 1, end
    newSound [i] = Extract part: begZ, endZ, "Rectangular", 1.0, "no"
    # get the bit of the TextGrid
    textGrid [i] = Read from file: fileDir$ + spkrName$ + "/textgrids/" + file$ + ".TextGrid"
    newTextGrid [i] = Extract part: begZ, endZ, "no"
    # remove any tiers which are not called 'segments' or 'words'
    tgTiers = Get number of tiers
    for n to tgTiers
      tierName$ = Get tier name: n
      if tierName$ <> "segments" and tierName$ <> "words"
        Remove tier: n
      endif
    endfor
  endfor

  # select all the relevant Sounds and concatenate them
  selectObject ()
  for i from 1 to numberOfFiles
      plusObject: newSound [i]
  endfor
  chainSnd = Concatenate
  # maximise audibility of the Sound
  Scale peak: 0.99
  # save the sound as a wav
  Save as WAV file: saveDir$ + "wav/" + spkrName$ + ".wav"

  # select all the right TextGrids and concatenate them
  selectObject ()
  for i from 1 to numberOfFiles
      plusObject: newTextGrid [i]
  endfor
  chainTG = Concatenate
  # fix the duplicated intervals where sentences have been joined
  procedure removeLabels
    b = Get end time of interval: t, x
    Remove boundary at time: t, b
    ints = ints-1
  endproc
  tiers = Get number of tiers
  # go through each tier
  for t to tiers
    ints = Get number of intervals: t
    # check each label on the tier
    for x to ints-1
      lab$ = Get label of interval: t, x
      labNext$ = Get label of interval: t, x+1
      # if there are adjacent 'sil' labels on tier 1, replace with one
      if t = 1 and lab$ = "sil" and labNext$ = "sil"
          @removeLabels
          Set interval text: t, x, "sil"
      # if there are adjacent 'SENT-END' labels on tier 2, replace with one
      elsif t = 2 and lab$ = "SENT-END" and labNext$ = "SENT-END"
          @removeLabels
          Set interval text: t, x, "SENT-END"
      endif
    endfor
  endfor

  # read the WAV file back in
  wav = Read from file: saveDir$ + "wav/" + spkrName$ + ".wav"
  wavDur = Get total duration

  # scale the TextGrid to the exact duration of the WAV file -
  # because WAV files are lossy the duration of the WAV file will be slightly 
  # different from the duration of the Sound object before it was saved. 
  # The difference between a Sound object and a saved WAV file may be 
  # in the order of one sample duration i.e. 1/44100 second, 
  # or 0.000022676 s.
  selectObject: chainTG
  Scale times to: 0, wavDur

  # move boundaries on all tiers to nearest hundredth of a second
  for t to tiers
    tierName$ = Get tier name: t
    numInt = Get number of intervals: t
    Insert interval tier: t+1, tierName$
    for x to numInt-1
      intEnd = Get end time of interval: t, x
      intLab$ = Get label of interval: t, x
      lastTime = Get start time of interval: t+1, x
      if 'lastTime:2' <> 'intEnd:2'
        Insert boundary: t+1, 'intEnd:2'
      # if rounding would put a boundary where a boundary already exists, 
      # retain the original position for the boundary
      else
        Insert boundary: t+1, intEnd
      endif
      Set interval text: t+1, x, intLab$
    endfor
    Remove tier: t
  endfor

  # save the TextGrid
  Save as text file: saveDir$ + "textgrids/" + spkrName$ + ".TextGrid"

  # cleans up
  selectObject ()
  for i from 1 to numberOfFiles
    plusObject: newSound [i], textGrid [i], sound [i], textGridSil [i], newTextGrid [i], wav
  endfor
  plusObject: strings, chainSnd, chainTG
  Remove
endfor

selectObject: spkrs
Remove
