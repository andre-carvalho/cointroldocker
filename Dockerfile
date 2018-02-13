FROM python:3

LABEL maintainer="afacarvalho@yahoo.com.br"

WORKDIR /usr/local/bitcointoyou

# Clone the webapp Cointrol
RUN git clone https://github.com/andre-carvalho/cointrol.git

# Clone the bitcointoyou library
RUN cd cointrol/cointrol && \
    git clone https://github.com/andre-carvalho/libbitcointoyou.git && \
    cd ../..

# Create a local settings file
RUN echo 'from .settings_prod import *' > cointrol/cointrol/conf/settings_local.py

# Install Python requirements
RUN pip install -r cointrol/cointrol/conf/requirements.txt

# Initialize the database
RUN cointrol/manage.py migrate

# Install cointrol-*
RUN pip install -e ./cointrol

# Install the package manager for Node.js to build the Cointrol app.
RUN apt-get update && \
    apt-get install -y nodejs && \
    apt-get install -y npm && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    npm install -g n && \
    n latest

# Build app
RUN npm -g install bower && \
    cd cointrol/webapp && \
    npm install && \
    bower install --allow-root && \
    npm install -g brunch && \
    npm install -g sass && \
    brunch build

#  Create a Django user (no-interactive step)
RUN echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(email='afacarvalho@yahoo.com.br', is_superuser=True).delete(); User.objects.create_superuser('admin', 'afacarvalho@yahoo.com.br', '12qwaszx')" | /usr/local/bitcointoyou/cointrol/manage.py shell

# Create the start script to cointrol-server and cointrol-trader
RUN echo "#!/bin/bash" > cointrol/startserver.sh
RUN echo "cointrol-server &" >> cointrol/startserver.sh
RUN echo "cointrol-trader &" >> cointrol/startserver.sh
RUN chmod +x cointrol/startserver.sh

# Start cointrol-server and cointrol-trader
CMD cointrol/startserver.sh ; sleep infinity

EXPOSE 8000
