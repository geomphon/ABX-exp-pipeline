#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Created october 2019
    by Juliette MILLET
    last edit Nov 15 2019 Amelia KIMBALL
    script to convert csv list of triplets for test into lmeds sequence format
"""
import os

line_exp = "I am an experiment line filename\n" #media_choice one_play_two_responses audio 0.5 1 1 [[filename]][1 2] bindPlayKeyIDList=[space] bindResponseKeyIDList=[f j]\n"
line_break = "I am a break line \n" #"text_page prot_pause bindSubmitKeyIDList=[space]\n"
file_easy_french = ["hibou_caillou_hibou2", "caillou_hibou_caillou_whisper", "hibou_caillou_caillou2", "hibou_caillou_hibou_whisper", "caillou_hibou_caillou", "caillou_hibou_hibou2"]
file_easy_english = ["dog_cat_dog2", "dog_cat_cat_whisper", "dog_cat_cat2", "cat_dog_cat_whisper", "cat_dog_dog2", "cat_dog_cat2"]


def get_template_lmeds(file_begin):
    f = open(file_begin, 'r')
    inside = f.readlines()
    return inside

def get_list_file(file_with_list):
    f = open(file_with_list, 'r')
    ind = f.readline().replace('\n', '').split('\t')

    list_file = []
    for line in f:
        new_line = line.replace('\n', '').split('\t')
        list_file.append(new_line[ind.index('filename')])
    f.close()
    return list_file

def create_template(file_with_list, language, file_out, task_name):
    beg = get_template_lmeds(os.path.join('templates/', 'template_begin_' + language + '.txt'))
    en = get_template_lmeds(os.path.join('templates/', 'template_end_' + language + '.txt'))

    f = open(file_out, 'w')

    list_files = get_list_file(file_with_list=file_with_list)
    # beginnig of the file
    f.write('*' + task_name+ '\n')
    for l in beg:
        f.write(l)
    f.write('\n')

    # real tests
    space_between_breaks = 64
    space_between_test = 39
    count_test = 0
    count_break = 0
    nb_test = 0
    for file in list_files:
        f.write(line_exp.replace('filename', file))
        count_test+=1
        count_break+=1

        # we add a break
        if count_break == space_between_breaks:
            f.write(line_break)
            count_break = 0

        # we add a test
        if count_test == space_between_test:
            print(nb_test)
            if language == 'french':
                f.write(line_exp.replace('filename', file_easy_french[nb_test]))
            else:
                f.write(line_exp.replace('filename', file_easy_english[nb_test]))
            count_test = 0
            nb_test += 1

    # end of the test
    for l in en:
        f.write(l)

    f.close()






def create_all_templates(folder_lists, folder_out_sequence, language):
    for filename in os.listdir(folder_lists):
        if filename.endswith(".csv"):
            task =  language + '_0'
            # sequence file for lmeds, you will have to move it
            create_template(file_with_list=os.path.join(folder_lists, filename), language = language,
                            file_out=os.path.join(folder_out_sequence, filename[:-4] + '.txt'), task_name=task)

        else:
            continue

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description='script to convert csv file with list of triplets in it into sequence and cgi files to use lmeds')
    parser.add_argument('folder_list', metavar='f_do', type=str,
                        help='folder where the list of triplets are')
    parser.add_argument('folder_out_sequence', metavar='f_out', type=str,
                        help='The folder where to put the sequence.txt files')
    parser.add_argument('language', metavar='lang', type=str,
                        help='language you are dealing with')

    args = parser.parse_args()
    create_all_templates(folder_lists=args.folder_list, folder_out_sequence=args.folder_out_sequence, language=args.language)