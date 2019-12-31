# Cut all labelled intervals in a TextGrid
#
# Author: Ewan Dunbar

from textgrid import TextGrid
from pydub import AudioSegment
import sys, argparse
import os
import os.path as osp
import pandas as pd


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


def normalize_amplitude(sound, target_dbfs):
    return sound.apply_gain(target_dbfs - sound.dBFS)


def BUILD_ARGPARSE():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('item_file', help="Item file name", type=str)
    parser.add_argument('interval_folder',
                        help="Output interval folder name",
                        type=str)
    return parser


if __name__ == "__main__":
    parser = BUILD_ARGPARSE()
    args = parser.parse_args(sys.argv[1:])

    if not os.path.isdir(args.interval_folder):
        os.makedirs(args.interval_folder)
    items = pd.read_csv(args.item_file)
    for _, interval in items.iterrows():
        try:
            audio = AudioSegment.from_wav(interval['#file'])
        except Exception as e:
            eprint("""Problem reading audio file: <M>""".replace(
                "<M>", str(e)).replace("\n", " "))
            sys.exit(1)
        filename = interval['#item'] + '.wav'
        onset_ms = round(interval['onset'] * 1000)
        offset_ms = round(interval['offset'] * 1000)
        segment_raw = audio[onset_ms:(offset_ms + 1)]
        segment = normalize_amplitude(segment_raw, -20)
        segment.export(args.interval_folder + "/" + filename, format="wav")
