FROM chbrandt/centos:heasoft

MAINTAINER "Carlos Brandt <carloshenriquebrandt at gmail>"

ENV HEASOFT_TMPDIR  /tmp/heasoft

COPY src $HEASOFT_TMPDIR

RUN source $HEASOFT_TMPDIR/install_heasoft.sh && \
    install && \
    rm -rf $HEASOFT_TMPDIR

RUN git clone https://github.com/chbrandt/docker_commons.git && \
    ln -sf docker_commons/entrypoint.sh /.

COPY home $HEASOFT_TMPDIR
RUN cat $HEASOFT_TMPDIR/non_interactive.rc \
        $HEASOFT_TMPDIR/ximage_exit_on_fail.rc \
        $HEASOFT_TMPDIR/ximage_no_history.rc \
    >> /etc/.bash_profile && \
    rm -rf $HEASOFT_TMPDIR

ENTRYPOINT ["/entrypoint.sh"]

