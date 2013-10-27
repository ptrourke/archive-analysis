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

/* Input: The complete set of nodes with their PR scores
 * Output: The set of all nodes with their PageRank rank and their Pagerank score 
 */

%default I_PR_SCORES_ALL_NODES '/search/nara/congress112th/pr-iterations/pr-id.graph_8.gz';
%default O_PR_RANK_ALL_NODES '/search/nara/congress112th/pr-rank-nodeid-score-all-nodes.gz';

pagerankFromGraph = LOAD '$I_PR_SCORES_ALL_NODES' as (id:chararray, pagerank:double);
prRanks = RANK pagerankFromGraph by pagerank DESC;

STORE prRanks INTO '$O_PR_RANK_ALL_NODES';
