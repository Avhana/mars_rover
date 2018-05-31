require './rover'

RSpec.describe Rover do
  let(:subject) { Rover.new }

  describe '#move' do
    it 'returns 0,0  for the initial position' do
      expect(subject.position).to eq([0, 0])
    end

    it 'returns :n for initial heading' do
      expect(subject.heading).to eq(:n)
    end

    it 'tracks multiple moves in the same direction' do
      make_moves([[:n, 1], [:n, 1]])
      expect(subject.position).to eq([0, 2])
    end

    it 'tracks the heading after each move' do
      make_moves([[:n, 1], [:w, 1]])
      expect(subject.heading).to eq(:w)
    end

    it 'tracks single moves of > 1 distance' do
      make_moves([[:n, 3]])
      expect(subject.position).to eq([0, 3])
    end

    it 'tracks moves in different directions' do
      make_moves([[:w, 2], [:n, 1], [:s, 4]])
      expect(subject.position).to eq([-2, -3])
    end

    it 'has a range of 10 on a single charge' do
      make_moves([[:n, 11]])
      expect(subject.position).to eq([0, 10])
    end

    it 'has a range of 10 across n moves' do
      make_moves([[:n, 4], [w: 6], [s: 2]])
      expect(subject.position).to eq([-6, 4])
    end
  end
end

describe '#recharge' do
  it 'has 0 charge after 10 moves' do
    make_moves([[:n, 10]])
    expect(subject.charge).to eq(0)
  end

  it 'recharges from 0 to 10 with a wait time of 8 hr' do
    make_moves([[:n, 10]])
    charge(8)
    expect(subject.charge).to eq(10)
  end

  it 'recharges from 0 to 5 with a wait time of 4 hr' do
    make_moves([[:n, 10]])
    charge(4)
    expect(subject.charge).to eq(5)
  end

  it 'recharges from 0 to 2.5 with a wait time of 2 hr' do
    make_moves([[:n, 10]])
    charge(2)
    expect(subject.charge).to eq(2.5)
  end
end

describe 'range and max_range' do
  let(:params) do
    { start_time: 0, hrs_of_light: 18 }
  end

  it 'has a max range of 15 at dawn (0 hrs)' do
    expect(subject.max_range).to eq(15)
  end

  it 'has a range of 0 at 10 hours' do
    make_moves([[:n, 10]])
    expect(subject.range).to eq(0)
  end

  it 'has a max range of 5 at 10 hours' do
    make_moves([[:n, 10]])
    expect(subject.range).to eq(5)
  end

  it 'as a range of 2 after charging fr 2 hours' do
    make_moves([[:n, 10]])
    charge(2)
    expect(subject.range).to eq(2)
  end

  it 'has a max_range of 10 if it starts at mid day, for 18hr of light' do
    rover = Rover.new(start_time: 9, hrs_of_light: 18)
    expect(rover.max_range).to eq(10)
  end
end

describe 'integration' do
  # note, the rover ignores move commands and recharge commands at night
  it 'moves, charges, and moves until night' do
    rover = Rover.new(start_time: 0, hrs_of_light: 18, day_length: 24)
    make_moves([[:w, 4], [:n, 1], [:s, 4], [:e, 1]]) # move 10
    charge(4)
    make_moves([[:w, 5]])
    expect(subject.position).to eq([-8, -3])
    wait(6)
    expect(rover.charge).to eq(1)
    make_moves([[:w, 1]])
    expect(rover.charge).to eq(0)
    charge(8)
    expect(subject.range).to eq(10)
    make_moves([[:n, 10]])
    expect(subject.position).to eq([-9, 6])
    expect(subject.max_range).to eq(0)
  end
end

def make_moves(moves)
  moves.each do |direction, distance|
    subject.move(direction, distance)
  end
end

def charge(time)
  subject.recharge(time)
end
