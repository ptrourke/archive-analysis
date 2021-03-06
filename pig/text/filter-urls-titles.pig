/*
 * Copyright 2013 Internet Archive
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License. You
 * may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

/* Input: Lines containing the URLs and titles
 * Input: Lines containing the SURT and original forms of the URL to find in the titles dataset
 * Input: Lines containing the original URLs with the titles
 */

%default I_URL_TITLE_DIR '/search/nara/congress112th/analysis/url.title.gz';
%default I_URL_ORIGURL_TO_FIND_DIR '/search/nara/congress112th/analysis/youtube-watch-url-origurl/';
%default O_FILTERED_ORIGURL_TITLE_DIR '/search/nara/congress112th/analysis/youtube-watch.origurl.title.gz'

TitleLines = LOAD '$I_URL_TITLE_DIR' AS (url:chararray, title:chararray);
Urls = LOAD '$I_URL_ORIGURL_TO_FIND_DIR' AS (url:chararray, origurl:chararray);

Joined = JOIN Urls BY url, TitleLines BY url;
Joined = FOREACH Joined GENERATE Urls::origurl as origurl, TitleLines::title as title;
STORE Joined INTO '$O_FILTERED_ORIGURL_TITLE_DIR';
