from __future__ import print_function

import sys
import argparse
import os.path as osp

import numpy as np
import pandas as pd
import scipy

import shennong.features.pipeline as snpipeline
from fastdtw import fastdtw
from joblib import Parallel, delayed


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)  # FIXME WRAP


def cosine_distance(x, y):
    '''[summary]
    
    :param x: [description]
    :type x: [type]
    :param y: [description]
    :type y: [type]
    '''
    xnorm = np.sqrt(np.sum(x**2))
    ynorm = np.sqrt(np.sum(y**2))
    cos = np.dot(x, y) / (xnorm * ynorm)
    return scipy.arccos(cos) / np.pi


def dtw_cosine_mean(x, y):
    '''[summary]
    
    :param x: [description]
    :type x: [type]
    :param y: [description]
    :type y: [type]
    :return: [description]
    :rtype: [type]
    '''
    dtw = fastdtw(x, y, dist=cosine_distance)
    return dtw[0] / len(dtw[1])


def get_midpoints(features):
    '''Retrieve frame midpoint times from Shennong Features object,
    calculating and caching them in the feature object if they don't exist.
    
    :param features: Shennong features object
    :type features: shennong.features.features.Features
    '''
    try:
        result = features.midpoints
    except AttributeError:
        features.midpoints = (features.times[:, 0] + features.times[:, 1]) / 2.
        result = features.midpoints
    return result


def nearest_frame(time, midpoints):
    '''Returns index of frame with the nearest midpoint to a given time.
    
    :param time: Time to find
    :type time: float
    :param midpoints: Frame midpoints
    :type midpoints: ndarray
    '''
    return np.argmin(np.abs(midpoints - time))


def get_item(features, utterance_id, onset, offset):
    '''Get features corresponding to a chunk of a file
   
    :param features: Dictionary of features
    :type features: dict 
    :param utterance_id:  Utterance ID (key into feature dictionary)
    :type filename: str 
    :param onset: Onset time (seconds)
    :type onset: float 
    :param offset: Offset time (seconds)
    :type offset: float
    :return: Features corresponding to the requested chunk
    :rtype: ndarray
    '''
    midpoints = get_midpoints(features[utterance_id])
    frame_onset = nearest_frame(onset, midpoints)
    frame_offset = nearest_frame(offset, midpoints)
    return features[utterance_id].data[frame_onset:frame_offset, ]  # FIXME: 0?


def calculate_distances(pairs,
                        features,
                        utterance_ids,
                        distance_fn=dtw_cosine_mean,
                        njobs=1):
    '''Calculate distances between given pairs.
    
    :param pairs: Pairs to be calculated
    :type pairs: Pandas DataFrame
    :param features: A dictionary of Shennong Features objects, indexed by
    (filename, speaker) tuples
    :type features: dict
    :param utterance_ids: A dictionary mapping (file, speaker) pairs to
    utterance_ids
    :type utterance_ids: dict
    :param distance_fn: A distance function applying to pairs of ndarrays
    :type distance_fn: function
    :return: A list of distance values
    :rtype: list
    '''
    return Parallel(n_jobs=njobs)(
        delayed(distance_fn)(
            get_item(features, utterance_ids[(pairs.iloc[i].loc['file_1'],
                               pairs.iloc[i].loc['speaker_1'])],
                               pairs.iloc[i].loc['onset_1'],
                               pairs.iloc[i].loc['offset_1']),
            get_item(features, utterance_ids[(pairs.iloc[i].loc['file_2'],
                               pairs.iloc[i].loc['speaker_2'])],
                               pairs.iloc[i].loc['onset_2'],
                               pairs.iloc[i].loc['offset_2'])) 
        for i in range(len(pairs)))


def BUILD_ARGPARSE():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--njobs', help="Number of parallel jobs", type=int)
    parser.add_argument('pair_file', help="Pair file", type=str)
    parser.add_argument('shennong_config_file',
                        help="Shennong feature extraction config file",
                        type=str)
    parser.add_argument('output_file', help="Output file", type=str)
    return parser


if __name__ == "__main__":
    parser = BUILD_ARGPARSE()
    args = parser.parse_args(sys.argv[1:])
    try:
        pairs = pd.read_csv(args.pair_file)
    except Exception as e:
        eprint("""Issue with pair file (<F>): <M>""".replace(
            "<F>", str(args.pair_file)).replace("<M>",
                                                str(e)).replace("\n", " "))
        sys.exit(1)
    

    items_1 = pairs[[
        c for c in pairs.columns if len(c) > 2 and c[-2:] == "_1"
    ]]
    items_1.columns = [c[:-2] for c in items_1.columns]
    items_2 = pairs[[
        c for c in pairs.columns if len(c) > 2 and c[-2:] == "_2"
    ]]
    items_2.columns = [c[:-2] for c in items_2.columns]
    if set(items_1.columns) != set(items_2.columns):
        eprint("""Issue with pair file (<F>):
columns don't match""".replace("<F>", str(args.pair_file)))
        sys.exit(1)
    if not set(['file', 'onset', 'offset', 'speaker']).issubset(
            items_1.columns):
        eprint("""Issue with pair file (<F>): missing 'file', 'speaker',
'onset', or 'offset' column(s)""".replace("<F>", str(args.pair_file)))
        sys.exit(1)
    items = pd.concat([items_1, items_2], sort=True).drop_duplicates()
    file_spk_ = items[['file', 'speaker']].drop_duplicates()
    utterance_index = [(str(i), ) + tuple(x)
                       for (i, x) in enumerate(file_spk_.values)]
    utterance_ids = dict(((f, s), uid) for (uid, f, s) in utterance_index)

    features = snpipeline.extract_features(args.shennong_config_file,
                                           utterance_index,
                                           njobs=args.njobs)
    pairs['distance'] = calculate_distances(pairs, features, utterance_ids,
                                            njobs=args.njobs)
    pairs.to_csv(args.output_file, index=False)
