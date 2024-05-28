function data2 = trim_data(data, accepted_time_range)
assert(accepted_time_range(2) > accepted_time_range(1), "trimming range wrong")

t = data.time;
inrange = t >= accepted_time_range(1) & t <= accepted_time_range(2);
data2 = DataClass;
data2.time = t(inrange);
% data2.time = data2.time - data2.time(1);
data2.dataTimeSeries = data.dataTimeSeries(inrange, :);
data2.measurementList = data.measurementList;
end