# Generate all possible triplets
# Author: Nicolas Brasset, Ewan Dunbar

import pandas as pd
import numpy as np
import sys, argparse


def remove_hash(df):
    return df.rename(columns=lambda s: s.replace("#", ""))


def add_suffix(df, suffix):
    return df.rename(columns=lambda s: s + suffix)


def duplicate_n(df, n):
    return df.iloc[np.repeat(np.arange(df.shape[0]), n)].reset_index(drop=True)


def repeat_n(df, n):
    return df.iloc[np.tile(np.arange(df.shape[0]), n)].reset_index(drop=True)


def cart_prod(df_a, df_b):
    df_a['KEY'] = 0
    df_b['KEY'] = 0
    return pd.merge(df_a, df_b).drop("KEY", axis=1)


parser = argparse.ArgumentParser(
    description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument(
    '--constraints-ab',
    type=str,
    default=None,
    help="additional constraints to place on the target/other pairs")
parser.add_argument(
    '--constraints-ax',
    type=str,
    default=None,
    help="additional constraints to place on the target/X pairs")
parser.add_argument(
    'input_path',
    help=
    "filename of the file created by add_meta_information_to_item_file.Rscript",
    type=str)
parser.add_argument('output_path',
                    help="filename for the output file",
                    type=str)
args = parser.parse_args()

soundsdf = pd.read_csv(args.input_path)
soundsdf_a = add_suffix(remove_hash(soundsdf[:]), "_TGT")
soundsdf_b = add_suffix(remove_hash(soundsdf[:]), "_OTH")
soundsdf_x = add_suffix(remove_hash(soundsdf[:]), "_X")

soundsdf_ab = cart_prod(soundsdf_a, soundsdf_b)\
        .query("phone_TGT != phone_OTH")
if args.constraints_ab is not None:
    soundsdf_ab = soundsdf_ab.query(args.constraints_ab)
soundsdf_ax = cart_prod(soundsdf_a, soundsdf_x)\
        .query("phone_TGT == phone_X")
if args.constraints_ax is not None:
    soundsdf_ax = soundsdf_ax.query(args.constraints_ax)

soundsdf_abx = pd.merge(soundsdf_ab, soundsdf_ax) # Risks running out of memory

triplet_ixs = range(1, len(soundsdf_abx) + 1)
digits = len(str(triplet_ixs[-1]))
triplet_ids = ['t_' + format(n, '0' + str(digits) + 'd') for n in triplet_ixs]
soundsdf_abx['triplet_id'] = triplet_ids

soundsdf_abx.to_csv(args.output_path, index=False)
