#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2020 Tong LI <tongli.bioinfo@protonmail.com>
#
# Distributed under terms of the BSD-3 license.

"""
Create .ijm to estimate tile shifts on DAPI channel
"""
import argparse
from generate_bigstitcher_macro import BigStitcherMacro
from pathlib import Path


def main(args):
    print(args.xml)
    macrocreater = BigStitcherMacro()
    macrocreater.img_dir=Path(args.img_dir)
    macrocreater.out_dir=Path("./")
    macrocreater.xml_folder=Path(args.xml_folder)
    macrocreater.xml_file_name=Path(args.xml).name
    macrocreater.pattern=args.pattern_str
    macrocreater.tiling_mode="snake"
    macrocreater.region=Path(args.xml).stem
    macrocreater.generate()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-xml", type=str,
            required=True)
    parser.add_argument("-img_dir", type=str,
            required=True)
    parser.add_argument("-pattern_str", type=str,
            required=True)
    parser.add_argument("-xml_folder", type=str,
            required=True)
    args = parser.parse_args()

    main(args)
