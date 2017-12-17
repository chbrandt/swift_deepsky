FROM chbrandt/swift_deepsky:6.15

RUN cd / && rm -rf /swift_deepsky && \
    git clone https://github.com/chbrandt/swift_deepsky.git && \
    cd /swift_deepsky && ./install.sh

ENV EXECAPP /swift_deepsky/bin/pipeline.sh
