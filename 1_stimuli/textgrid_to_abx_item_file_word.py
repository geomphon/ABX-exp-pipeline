# Convert Textgrids to an ABXpy item file for doing
# word ABX (i.e., containing one column, word)
#
# Author: Ewan Dunbar

from __future__ import print_function

from textgrid import TextGrid
import sys, argparse
import os.path as osp
import glob


class TextGridError(RuntimeError):
    pass


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)  # FIXME WRAP


def get_intervals(textgrid_fn, tier_name):
    tg = TextGrid()
    tg.read(textgrid_fn)
    try:
        tier_i = tg.getNames().index(tier_name)
    except ValueError:
        raise TextGridError("Cannot find tier named " + tier_name)
    return tg[tier_i]


def is_target_word(word, target_words):
    return word != "" \
            and ((len(target_words) == 0) or (word in target_words))


def print_abx_item_file_header():
    print("#file onset offset #item word interval")


def print_abx_item_file_line(filename, interval, item_id, interval_number):
    print(filename + " " + str(interval.minTime) + " " \
            + str(interval.maxTime) + " " + str(item_id) \
            + " " + interval.mark + " " + str(interval_number))


def BUILD_ARGPARSE():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--excluded-words', help="List of word targets " \
            "to exclude, separated by comma (defaults to none)", default=None,
            type=str)
    parser.add_argument('--target-words', help="List of word targets " \
            "to include, separated by comma (defaults to all)", default=None,
            type=str)
    parser.add_argument('tier_name', help="Name of TextGrid tier", type=str)
    parser.add_argument('textgrid_path',
                        help="directory containing .TextGrid files",
                        type=str)
    parser.add_argument(
        'wavfile_path',
        help="directory containing .wav files corresponding to .TextGrid files",
        type=str)

    return parser


if __name__ == "__main__":
    parser = BUILD_ARGPARSE()
    args = parser.parse_args(sys.argv[1:])

    textgrid_files = glob.glob(osp.join(args.textgrid_path, "*.TextGrid"))
    wav_files = glob.glob(osp.join(args.wavfile_path, "*.wav"))

    target_words = []
    if args.target_words is not None:
        target_words = args.target_words.split(',')
    excluded_words = []
    if args.excluded_words is not None:
        excluded_words = args.excluded_words.split(',')

    textgrid_wavefile_pairs = []
    for tgf in textgrid_files:
        tg_root = osp.splitext(osp.split(tgf)[1])[0]
        wavf = osp.join(args.wavfile_path, tg_root) + ".wav"
        if wavf in wav_files:
            textgrid_wavefile_pairs.append((tgf, wavf))

    print_abx_item_file_header()
    for f_tg, f_wav in textgrid_wavefile_pairs:
        try:
            tier = get_intervals(f_tg, args.tier_name)
        except Exception as e:
            eprint("""Problem reading TextGrids: <M>""".replace(
                "<M>", str(e)).replace("\n", " "))
            sys.exit(1)
        index_number = 1
        for interval in tier:
            if interval.mark != "":
                if is_target_word(interval.mark, target_words) \
                        and not interval.mark in excluded_words:
                    wavfile_stripped = osp.splitext(osp.basename(f_wav))[0]
                    item_id = wavfile_stripped + "_" + str(index_number)
                    print_abx_item_file_line(f_wav, interval, item_id,
                                             index_number)
                index_number += 1
