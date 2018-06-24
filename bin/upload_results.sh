upload_results (){
  local OUTDIR="$1"
  [ -d "$OUTDIR" ] || return 1
  local TARBALL="${OUTDIR}.tar"
  (
    cd ${OUTDIR}/..
    OUTDIR=$(basename ${OUTDIR})
    tar -cf $TARBALL ${OUTDIR}
    [[ -f $TARBALL ]] && \
        sshpass -p "swiftxrt2018" \
            scp -o UserKnownHostsFile=/dev/null \
                -o StrictHostKeyChecking=no \
                -o ConnectTimeout=10 \
                $TARBALL deepsky@deepsky.servebeer.com:~/upload/
  )
  [[ -f $TARBALL ]] && rm $TARBALL
}
