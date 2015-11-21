#!/usr/bin/env ruby
# encoding: utf-8

require 'pry'
module Enumerable
  def median
    sorted = self.sort
    half_len = (sorted.length / 2.0).ceil
    (sorted[half_len-1] + sorted[-half_len]) / 2.0
  end

  def sum
    self.inject(0){|accum, i| accum + i }
  end

  def mean
    self.sum/self.length.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

end

REPEAT_COLUMN_COUNT = 9
DATA_ORDER = [:sleeping, :smoking, :drinking, :personality1, :personality2, :cleaning]
DATA_IDX = {
  me: 3,
  roommate_now: 4,
  roommate_post: 5,
  satisfaction_now: 7
}

DATA_LOOKUP_TABLE = {
  sleeping: ["10시 이전", "10시 ~ 12시", "12시 ~ 2시", "2시 ~ 4시", "4시 이후"],
  smoking: ["흡연", "비흡연"],
  drinking: ["월 1회 이하", "월 1회 ~ 3회", "주 1회", "주 2회 ~ 주 3회", "주 3회 이상"],
  personality1: ["매우 아니다", "아니다", "보통이다", "인정", "매우 인정"],
  personality2: ["매우 아니다", "아니다", "보통이다", "인정", "매우 인정"],
  cleaning: ["한달 1회 이하", "한달 2 ~ 3회", "주 1회", "주 3~5회", "주 5회 이상"]
}

IMPORTANCE_FACTOR = {
  sleeping:0.52,
  smoking:0.47,
  drinking:0.28,
  personality1:0.54,
  personality2:0.56,
  cleaning:0.71
}

LAST_USER_NUMBER = 10

def calculate_distance(a, b)
  distance = 0
  DATA_ORDER.each do |data_sym|
    distance += (a[data_sym][:me] - b[data_sym][:me]).abs * IMPORTANCE_FACTOR[data_sym]
  end

  distance
end

def main
  puts "start main"
  f = File.open("data.csv");

  datas = f.read().split("\r\n").select{|x| !x.match(",,,")}.map{|x| x.split(",")}
  datas.shift();
  datas = datas.sample(LAST_USER_NUMBER)

  users = {}
  datas.each_with_index do |d, idx|
    user_data = {}
    DATA_ORDER.each_with_index do |data_sym, data_order_idx|
      user_data[data_sym] ||= {}
      DATA_IDX.each do |k, v|
        user_data[data_sym][k] = d[data_order_idx * REPEAT_COLUMN_COUNT + v].to_i
      end
    end
    users[idx + 1] = user_data
  end

  user_distance_dic = {}
  users.each do |a_number, a|
    user_distance_dic[a_number] ||= {}
    users.each do |b_number, b|
      user_distance_dic[a_number][b_number] = calculate_distance(a,b)
    end
  end

  distance_min = 10000
  distance_min_matching = []
  distance_min_distances = []

  variance_min = 10000
  variance_min_matching = []
  variance_min_distances = []

  maxs_min = 10000
  maxs_min_matching = []
  maxs_min_distances = []
  arr = (1..LAST_USER_NUMBER).to_a.permutation.to_a
  arr.each do |matching|
    distances = []
    matching.each_slice(2) do |arr|
      distances << user_distance_dic[arr[0]][arr[1]]
    end
    total_distance = distances.sum
    if total_distance < distance_min
      distance_min_matching = matching
      distance_min = total_distance
      distance_min_distances = distances
    end

    variance = distances.sample_variance
    if variance < variance_min
      variance_min_matching = matching
      variance_min = variance
      variance_min_distances = distances
    end

    max = distances.max
    if max < maxs_min
      maxs_min_matching = matching
      maxs_min = max
      maxs_min_distances = distances
    end
  end

  sample_matching = arr.sample
  sample_distances = []
  sample_matching.each_slice(2) do |arr|
    sample_distances << user_distance_dic[arr[0]][arr[1]]
  end


  Hash[{
    distance_min: distance_min_distances,
    variance_min: variance_min_distances,
    maxs_min: maxs_min_distances,
    sample: sample_distances
  }.map do |k,v|
    [k, {
      mean: v.mean,
      variance: v.sample_variance,
      standard_deviation: v.standard_deviation,
      min: v.min,
      max: v.max,
      median: v.median
    }]
  end]
end


experiments = 20.times.map do
  main
end

result = {}
[:distance_min, :variance_min, :maxs_min, :sample].each do |factor|
  sum = {}
  experiments.each do |experiment|
    experiment[factor].each do |k,v|
      sum[k] ||= []
      sum[k] << v
    end
  end

  sum.each do |k, v|
    sum[k] = v.mean
  end
  result[factor] = sum
end

result.each do |k,v|
  puts ""
  puts "=================== #{k} ==================="
  puts "\t average : " + v[:mean].to_s
  puts "\t variance : " + v[:variance].to_s
  puts "\t standard_deviation : " + v[:standard_deviation].to_s
  puts "\t min : " + v[:min].to_s
  puts "\t max : " + v[:max].to_s
  puts "\t median : " + v[:median].to_s
  puts "=================== #{k} ==================="
  puts ""
end

