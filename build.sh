#!/bin/bash
aws s3 sync static/ s3://inso15teaser/
yesod keter
