ARG BUILD_FROM
FROM $BUILD_FROM

# Upstream: https://github.com/nodomain/mcp-cookidoo (MIT), fest auf einen geprüften Stand gepinnt
ARG MCP_COOKIDOO_REF=b097330

RUN apk add --no-cache git tailscale \
    && git clone https://github.com/nodomain/mcp-cookidoo /opt/mcp-cookidoo \
    && git -C /opt/mcp-cookidoo checkout "${MCP_COOKIDOO_REF}" \
    && rm -rf /opt/mcp-cookidoo/.git \
    && apk del git

# Land und Sprache sind upstream fest auf die Schweiz verdrahtet; hier per Umgebungsvariable einstellbar
RUN sed -i 's/get_localization_options(country="ch", language="de-CH")/get_localization_options(country=os.getenv("COOKIDOO_COUNTRY", "ch"), language=os.getenv("COOKIDOO_LANGUAGE", "de-CH"))/' \
        /opt/mcp-cookidoo/cookidoo_service.py \
    && grep -q 'os.getenv("COOKIDOO_COUNTRY"' /opt/mcp-cookidoo/cookidoo_service.py

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

COPY rootfs /
RUN chmod a+x /run.sh

WORKDIR /opt/mcp-cookidoo
CMD [ "/run.sh" ]
