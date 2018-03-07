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
            scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
                $TARBALL deepsky@90.147.69.218:/media/hd_upload 2> /dev/null
  )
  [[ -f $TARBALL ]] && rm $TARBALL
}
