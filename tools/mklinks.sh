#!/bin/bash

TS=$( date +'%Y%m%d-%H%M%S' )
UNIQ="$TS-$$"
OUTDIR="incoming"
STREAMDIR="STREAM"
UNDO="./.undo"

echo "It is recommended that you empty $OUTDIR before running this script." 1>&2
echo "You'll know that next time. You can run $UNDO to roll back." 1>&2
echo 

echo "#!/bin/bash" > $UNDO
echo >> $UNDO

find "$OUTDIR" -iname '*.MTS' | while read mts; do
  dest="$STREAMDIR/$UNIQ.$( basename "$mts" )"
  if [ ! -e "$dest" ]; then
    ln "$mts" "$dest"
    echo "$mts -> $dest"
    echo "rm '$dest'" >> $UNDO
  fi
done

chmod +x $UNDO

# vim:ts=2:sw=2:sts=2:et:ft=sh

