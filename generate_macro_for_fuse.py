#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2020 Tong LI <tongli.bioinfo@protonmail.com>
#
# Distributed under terms of the BSD-3 license.

"""
Take .xml and generate macro for bigstitcher fuse
"""
import argparse
from pathlib import Path
from generate_bigstitcher_macro import FuseMacro


def main(args):
    fuseMacroCreater = FuseMacro()
    fuseMacroCreater.img_dir=Path(args.img_dir)
    fuseMacroCreater.out_dir=Path(args.out_dir)
    fuseMacroCreater.xml_folder=Path(args.xml_folder)
    fuseMacroCreater.xml_file_name=Path(args.xml).name
    fuseMacroCreater = fuseMacroCreater.generate()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-xml", type=str,
            required=True)
    parser.add_argument("-img_dir", type=str,
            required=True)
    parser.add_argument("-xml_folder", type=str,
            required=True)
    parser.add_argument("-out_dir", type=str,
            required=True)

    args = parser.parse_args()

    main(args)
