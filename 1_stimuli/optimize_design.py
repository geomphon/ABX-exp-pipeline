# Authors: Adèle Richard and Ewan Dunbar

import argparse
import pandas as pd

import random
import numpy as np

import simanneal
import sklearn.metrics
import collections
import os
import sys
import csv
import random
import math
import signal


class ABXAnnealer(simanneal.Annealer):
    @staticmethod
    def n_columns():
        return 3  # AB-Order, Phone_pair, Speaker_triple

    @staticmethod
    def ab_order_col():
        return 0  # AB-Order, Phone_pair, Speaker_triple

    @staticmethod
    def phone_pair_col():
        return 1  # AB-Order, Phone_pair, Speaker_triple

    @staticmethod
    def speaker_triple_col():
        return 2  # AB-Order, Phone_pair, Speaker_triple

    @staticmethod
    def ab_orders():
        return {0: "TgtOth", 1: "OthTgt"}

    @staticmethod
    def ab_order_num(ab_orders):
        ab_order_nums = {"TgtOth": 0, "OthTgt": 1}
        return [ab_order_nums[ab_o] for ab_o in ab_orders]

    def __init__(self, triplets, init=None):
        self.triplets = triplets
        if init is not None:
            # FIXME: No guarantee init is compatible with triplets
            stim_types = init[[
                'speaker_TGT', 'phone_TGT', 'speaker_OTH', 'phone_OTH',
                'speaker_X'
            ]].drop_duplicates().reset_index(drop=True)
        else:
            stim_types = self.triplets[[
                'speaker_TGT', 'phone_TGT', 'speaker_OTH', 'phone_OTH',
                'speaker_X'
            ]].drop_duplicates().reset_index(drop=True)
        self.phone_pairs = {
            i: pp
            for i, pp in enumerate(stim_types[['phone_TGT', 'phone_OTH']].
                                   drop_duplicates().to_dict('records'))
        }
        self.phone_pairs_inv = {(pp['phone_TGT'], pp['phone_OTH']): i
                                for i, pp in self.phone_pairs.items()}
        self.speaker_triples = {
            i: st
            for i, st in enumerate(stim_types[[
                'speaker_TGT', 'speaker_OTH', 'speaker_X'
            ]].drop_duplicates().to_dict('records'))
        }
        self.speaker_triples_inv = {(st['speaker_TGT'], st['speaker_OTH'],
                                     st['speaker_X']): i
                                    for i, st in self.speaker_triples.items()}
        self.n_speaker_triples = len(self.speaker_triples)
        self.n_trials = len(self.phone_pairs) * len(ABXAnnealer.ab_orders())
        self.initialize_state(init)

    def initialize_state(self, init):
        if init is not None:
            assert len(init) == self.n_trials  # FIXME
        self.state = np.zeros((self.n_trials, ABXAnnealer.n_columns()))
        if init is not None:
            self.state[:, ABXAnnealer.ab_order_col()] \
                = ABXAnnealer.ab_order_num(init['AB_Order'])
            self.state[:, ABXAnnealer.phone_pair_col()] \
                = [self.phone_pairs_inv[x] for x in
                    init[['phone_TGT', 'phone_OTH']].\
                       itertuples(index=False, name=None)]
            self.state[:, ABXAnnealer.speaker_triple_col()] \
                = [self.speaker_triples_inv[x] for x in
                   init[['speaker_TGT', 'speaker_OTH', 'speaker_X']].\
                       itertuples(index=False, name=None)]
        else:
            self.state[:, ABXAnnealer.ab_order_col()] = np.tile(
                list(ABXAnnealer.ab_orders()), len(self.phone_pairs))
            self.state[:, ABXAnnealer.phone_pair_col()] = np.repeat(
                list(self.phone_pairs), len(ABXAnnealer.ab_orders()))
            self.state[:, ABXAnnealer.speaker_triple_col()] = np.random.choice(
                list(self.speaker_triples), size=self.n_trials, replace=True)

    def move(self):
        trial = random.randrange(self.n_trials)
        self.state[trial, ABXAnnealer.speaker_triple_col()] = random.randrange(
            len(self.speaker_triples))

    def energy(self):
        s = self.state
        pred_phone_from_spkr = sklearn.metrics.normalized_mutual_info_score(
            s[:, ABXAnnealer.phone_pair_col()],
            s[:, ABXAnnealer.speaker_triple_col()], average_method='arithmetic')
        pred_ab_order_from_spkr = sklearn.metrics.normalized_mutual_info_score(
            s[:, ABXAnnealer.ab_order_col()],
            s[:, ABXAnnealer.speaker_triple_col()], average_method='arithmetic')
        num_repetitions = self.n_trials \
            - sum([
                len(np.unique(s[s[:,ABXAnnealer.phone_pair_col()] == pp][:,
                    ABXAnnealer.speaker_triple_col()]))
                for pp in self.phone_pairs.keys()
            ])
        normalized_num_repetitions = num_repetitions / self.n_trials
        spk_used = np.unique(self.state[:,ABXAnnealer.speaker_triple_col()])
        prop_spk_used = len(spk_used)/self.n_speaker_triples
        prop_spk_missing = 1 - prop_spk_used
        return pred_phone_from_spkr + pred_ab_order_from_spkr \
            + normalized_num_repetitions + prop_spk_missing

    def state_df(self):
        ab_order = pd.DataFrame({
            "AB_Order": [
                ABXAnnealer.ab_orders()[x]
                for x in self.state[:, ABXAnnealer.ab_order_col()]
            ]
        })
        phone_pair = pd.DataFrame([
            self.phone_pairs[x]
            for x in self.state[:, ABXAnnealer.phone_pair_col()]
        ])
        speaker_triple = pd.DataFrame([
            self.speaker_triples[x]
            for x in self.state[:, ABXAnnealer.speaker_triple_col()]
        ])
        triplet_sample = self.triplets.sample(frac=1).groupby([
            'phone_OTH', 'phone_TGT', 'speaker_OTH', 'speaker_TGT', 'speaker_X'
        ]).first().reset_index()
        triplets_selected = pd.concat([ab_order, phone_pair, speaker_triple],
                                      axis='columns')
        return triplets_selected.merge(triplet_sample, how="left")


def BUILD_ARGPARSE():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('triplet_list', help="Triplet list file", type=str)
    parser.add_argument('--seed', help="Random seed", type=int, default=None)
    parser.add_argument(
        '--desired-energy',
        help="Re-run iteratively until this threshhold is crossed",
        type=float,
        default=None)
    parser.add_argument('--initialization',
                        help="Name of CSV containing previous design",
                        type=str,
                        default=None)
    parser.add_argument('output_file', help="Output file name", type=str)
    return parser


def handler(_signo, _stack_frame):
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, handler)
    signal.signal(signal.SIGINT, handler)
    parser = BUILD_ARGPARSE()
    args = parser.parse_args(sys.argv[1:])

    triplets = pd.read_csv(args.triplet_list)
    if args.seed is not None:
        random.seed(args.seed)
    if args.initialization is not None:
        init = pd.read_csv(args.initialization)
        opt = ABXAnnealer(triplets, init)
    else:
        opt = ABXAnnealer(triplets)
    initial_state = opt.state
    initial_energy = opt.energy()
    print("Initial energy: " + str(initial_energy), file=sys.stderr)
    if args.desired_energy is not None:
        desired_energy = args.desired_energy
    else:
        desired_energy = initial_energy
    print("Optimizing initial annealing schedule...", file=sys.stderr)
    sys.stderr.flush()
    initial_schedule = opt.auto(3, steps=100)
    sys.stderr.flush()
    improvement_schedule = initial_schedule
    improvement_schedule['tmax'] = initial_schedule['tmax'] * math.exp(
        -math.log(initial_schedule['tmax'] / initial_schedule['tmin']) * 0.99)
    opt.set_schedule(initial_schedule)
    opt.state = initial_state
    print("Iterating until energy drops below: " + str(desired_energy),
          file=sys.stderr)
    iteration = 1
    current_energy = initial_energy
    current_state = opt.state
    try:  # If interrupted, SystemExit() will be raised
        while current_energy >= desired_energy:
            print("Iteration " + str(iteration) + ": Improving design...",
                  file=sys.stderr)
            sys.stderr.flush()
            opt.anneal()
            sys.stderr.flush()
            new_energy = opt.energy()
            print("Iteration " + str(iteration) +
                  ": Energy after annealing: " + str(new_energy),
                  file=sys.stderr)
            if new_energy < current_energy:
                current_energy = new_energy
                current_state = opt.state
            else:
                print("Iteration " + str(iteration) +
                      ": Design did not improve, leaving unchanged",
                      file=sys.stderr)
                opt.state = current_state
            opt.set_schedule(improvement_schedule)
            iteration += 1
    except SystemExit:
        print("Interrupted, saving previous state as " + args.output_file +
              " (can be resumed using --initialization)",
              file=sys.stderr)
        opt.state = current_state
        s_df = opt.state_df()
        s_df.to_csv(args.output_file, index=False)
    s_df = opt.state_df()
    s_df.to_csv(args.output_file, index=False)
