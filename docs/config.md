# lnd config tuning

You can use environment variables to customize config ([see docker run environment options](https://docs.docker.com/engine/reference/run/#/env-environment-variables)):

        docker run -v lnd-data:/lnd --name=lnd-node -d \
            -p 9735:9735 \
            -p 10009:10009 \
            lnzap/lnd

Or you can use your very own config file like that:

        docker run -v lnd-data:/lnd --name=lnd-node -d \
            -p 9735:9735 \
            -p 10009:10009 \
            -v /etc/mylnd.conf:/lnd/.lnd/lnd.conf \
            lnzap/lnd
