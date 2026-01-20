FROM perl:5.38

# Install required Perl modules
RUN cpanm --notest Moo JSON Time::HiRes Test::More

# Create working directory
WORKDIR /app

# Copy all episode code
COPY 01/ /app/01/
COPY 02/ /app/02/
COPY 03/ /app/03/
COPY 04/ /app/04/
COPY 05/ /app/05/
COPY 06/ /app/06/
COPY 07/ /app/07/
COPY 08/ /app/08/

# Default command: run final version
CMD ["perl", "08/mock_api.pl"]

# Usage examples:
# docker build -t api-simulator .
# docker run api-simulator
# docker run api-simulator perl 01/mock_api.pl
# docker run api-simulator perl -w 08/t/01_basic.t
