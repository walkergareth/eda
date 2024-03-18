# A script to create a TextGrid containing reaction data to audio samples.

# Start with a Table selected which contains the times in a column,
# plus the corresponding Sound.

# Copyright (C) 2021 Gareth Walker.

# updated 2023-03-31 to use Praat's new syntax for forms

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

# information about objects
table = selected ("Table")
sound = selected ("Sound")

# form
form: "Create TextGrid from reaction data..."
  sentence: "Column_containing_times", "time"
endform

# simplify variable name
time_col$ = column_containing_times$

# copy and sort the table
selectObject: table
table_sort = Copy: "table_sort"
Sort rows: { time_col$ }
rows = Get number of rows

# get duration informatioan about the sound object
selectObject: sound
start = Get start time
end = Get end time

# create the TextGrid
tg = Create TextGrid: start, end, "reactions", "reactions"

# variable to remember the value from the previous row in the table
prevVal = 0

for r to rows
  selectObject: table_sort
  val = Get value: r, time_col$
  selectObject: tg
  # what to do if the current time is different from the previous time
  if val <> prevVal
    Insert point: 1, val, "X"
  # what to do if the current time is the same as the previous time
  elsif val = prevVal
    pointIndex = Get nearest index from time: 1, val
    pointLabel$ = Get label of point: 1, pointIndex
    newPointLabel$ = pointLabel$ + "X"
    Set point text: 1, pointIndex, newPointLabel$
  endif
  prevVal = val
endfor

# clean up
selectObject: table_sort
Remove
selectObject: tg