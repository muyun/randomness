function Ind = kNN(T,  Q, l, ncandid)
% the privacy-preserving kNN code ...
%
% T, Q    -  the binary set
%    l        -  the partition number
%  ncandid  -  the candidate number
%
%   Ind   -  return the ncandid candidate indices
%

T_n = size(T, 1);  % gallery
Q_n = size(Q, 1);  % probe
%ncandid = 10;  % selected candid

Ind = zeros(Q_n, ncandid);

% the threshold
Q1 = 100;
Q2 = 200;
SL = 20; % default step length

for i = 1 : Q_n % in probe
         % each instance q in the probe
         q = Q(i, :);
         Ind_ = [];
         
         for k = Q1: SL : Q2
               output = [];   % 
               iterno = []; 
            
                for j = 1 : T_n
                       % for each instance p
                        [result, iter] = stepind(T(j, :),  q,  k,  l);

                        % get the index i of the instance p,
                        if result == 0,
                              output =[output, j]; 
                              iterno = [iterno, iter];
                        end            
                end
                            %fprintf('The indexes of the %d near neighbors in T to the given query : \n', k);
                fprintf('NN(k<=%d) found: \n', k);
                fprintf('%5d', output);
%                 fprintf('\n No. iterations: \n');
%                 fprintf('%5d', iterno);
                fprintf('\n');
                
                Ind_ = [Ind_, setdiff(output, Ind_)];
            
         end
         
         len_ind_ = length(Ind_);
         if len_ind_ <= ncandid,
              Ind_(len_ind_ + 1 : ncandid) = 0;
         else
              Ind_(ncandid + 1 : len_ind_) = [];
         end
         
         Ind(i, :) = Ind_;
end

% get the ncandid index
Ind = Ind';

% the functions
function [re, iter] = stepind(p,  q, k, l, max_iter)
% check whether the binary vector p is the near neighbors of q ( H(p,q) <= k) with the options
% 
% INPUT:
%       p, q              -   the binary vector p, and the query q
%          k              -   the hamming distance
%          l              -   the partition number
%
%       max_iter          -   max. number of iteration (default: 100) 
%
% OUTPUT:
%           re            -   [0, 1] (0 means that p is the k nearneighbor of q; 1 is not)
%           iter          -   the interation num to get the instance p
%
 
if nargin < 5,
   max_iter = 100;
end

% C controls the stopping criteria
%len = length(p);
%C = (k / len) * l;
%C = l / len;
iter = 1;

% On the 1st layer, split p and q into l  substrings
p_substrings = arraySplit(p, l);
q_substrings = arraySplit(q, l); 
[p_new, q_new, m] = stepknn(p_substrings, q_substrings, l); 

if m == 0 % p = q  
    re = 0;    
elseif m > k, % p is not in NN(q)
    re = 1;
else  % m < k, p may be in NN(q)
    % this instance p might be the one we are looking for
    % goto the next layer
    for iter = 2 : max_iter  % on the 2nd layer now
        % It might use the different struct to deal with p_new, q_new
        % Create smaller segments by dividing each unequal cell by half
        p_substrings = cellSplit(p_new, 2);
        q_substrings = cellSplit(q_new, 2);
        [p_new, q_new, m] = stepknn(p_substrings, q_substrings, 2); 
        
        % check termination condition
        if m > k,
            re = 1;
            break;
        end

        len_p_new = length(p_new{1});

      % if m <  2^iter  *  C,  % H(p, q) <= k
       if m * len_p_new <= k, %
            re = 0;
            break;
       end

         % the last split
        if  (len_p_new ==1) && (m * len_p_new) > k,
              re = 1;
              break;
        end

    end 

end
        
function [p_new, q_new, m] = stepknn(p, q, l)
%SETPNEAR   One step in checking that p is in k near neighbors or not in Hamming space to a given query q
%
% p, q           -    cell of the binary data
% p_new, q_new   -    new cells stored the substrings having at least 1-bit error
% m              -    the number of substrings having at least 1-bit error
%

len_ps = numel(p);
%p_new = {};
%q_new = {}; 
p_new = cell(l, len_ps);
q_new = cell(l, len_ps);

m = 1;  % the index in matlab starts from 1

for i = 1 : len_ps 
       % for each substring 
       [res, err] = randomizedProtocol(p{i}, q{i}, l);
       %res =  isequal(p{i}, q{i});
%        disp(err);
%        fprintf('%.2f\n', err);
        if res == 1,  % pi != qi
            %m = m + 1;  
            %  put it in the new p and q  
            p_new{m} = p{i} ;
            q_new{m} = q{i} ;
            
            m = m + 1;
        end
       
end

%remove the empty cell
p_new(m:len_ps)= [];
q_new(m:len_ps)= [];

m = m - 1;